#!/bin/zsh
# Launchd-invoked heartbeat: wake a headless Claude to run the heartbeat skill.
# Configure via .env in the plugin dir or env vars (see templates/heartbeat.plist.template).
#   CLAUDE_ANIMA_PROJECT_DIR  — project to run the heartbeat in (default: $HOME)
#   CLAUDE_ANIMA_LOG          — log file (default: <project>/heartbeat.log)
#   CLAUDE_ANIMA_PROMPT       — prompt to send (default: run the heartbeat skill)
export PATH="/opt/homebrew/bin:$HOME/.local/bin:$PATH"

# Load .env next to this script if present (KEY=VALUE lines).
SCRIPT_DIR="${0:A:h}"
[ -f "$SCRIPT_DIR/../.env" ] && set -a && source "$SCRIPT_DIR/../.env" && set +a

PROJECT_DIR="${CLAUDE_ANIMA_PROJECT_DIR:-$HOME}"
LOG="${CLAUDE_ANIMA_LOG:-$PROJECT_DIR/heartbeat.log}"
PROMPT="${CLAUDE_ANIMA_PROMPT:-Run a heartbeat now using the heartbeat skill.}"

cd "$PROJECT_DIR" || exit 1

# Single-instance guard. Claude wakes each heartbeat as its own headless session,
# so an overrun (or a second trigger) could run two at once and contend for shared
# resources (e.g. a single Telegram bot token). macOS has no flock, so use an
# atomic mkdir lock keyed to the project; steal it if it's stale (>20 min crash).
LOCKDIR="/tmp/claude-anima-hb-$(printf '%s' "$PROJECT_DIR" | shasum | cut -c1-8).lock"
NOW=$(date +%s)
if ! mkdir "$LOCKDIR" 2>/dev/null; then
  if [ -d "$LOCKDIR" ] && [ $(( NOW - $(stat -f %m "$LOCKDIR" 2>/dev/null || echo "$NOW") )) -gt 1200 ]; then
    rmdir "$LOCKDIR" 2>/dev/null; mkdir "$LOCKDIR" 2>/dev/null || { echo "=== heartbeat skipped (lock) $(date) ===" >> "$LOG"; exit 0; }
  else
    echo "=== heartbeat skipped (another instance running) $(date) ===" >> "$LOG"; exit 0
  fi
fi
trap 'rmdir "$LOCKDIR" 2>/dev/null' EXIT

echo "=== heartbeat $(date '+%Y-%m-%d %H:%M:%S') ===" >> "$LOG"
claude -p "$PROMPT" --dangerously-skip-permissions >> "$LOG" 2>&1

# Cross-device sync: push any memory the heartbeat wrote/distilled (and pull
# remote changes). Fail-safe; no-ops when nothing changed.
"$SCRIPT_DIR/memory_sync.sh" >> "$LOG" 2>&1 || true
