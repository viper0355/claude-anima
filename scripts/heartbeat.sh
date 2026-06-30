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

# --- Cost gate: only wake the model when there's a real signal (free, zero tokens). ---
# Each heartbeat is a fresh headless session = real API cost. In a git project we can
# cheaply tell whether anything actually happened: working-tree changed since last
# beat, unpushed commits, or the periodic floor (CLAUDE_ANIMA_FLOOR_HOURS, default 5h).
# No signal → log a silent beat and exit WITHOUT waking the model. The reason is passed
# into the prompt so the wake is targeted. Non-git projects can't be gated → always run.
FLOOR_HOURS="${CLAUDE_ANIMA_FLOOR_HOURS:-5}"
GATE="${TMPDIR:-/tmp}/anima-gate-$(printf '%s' "$PROJECT_DIR" | shasum | cut -c1-8)"
REASONS=""
if git rev-parse --git-dir >/dev/null 2>&1; then
  GH=$(git status --porcelain 2>/dev/null | shasum | cut -d' ' -f1)
  UNP=$(git log @{u}..HEAD --oneline 2>/dev/null | wc -l | tr -d ' ')
  PH=""; LF=0
  [ -f "$GATE" ] && { PH=$(sed -n 1p "$GATE"); LF=$(sed -n 2p "$GATE"); }
  case "$LF" in ''|*[!0-9]*) LF=0;; esac
  HRS=$(( (NOW - LF) / 3600 ))
  [ "$GH" != "$PH" ] && REASONS="git changed"
  [ "${UNP:-0}" -gt 0 ] && REASONS="${REASONS:+$REASONS, }${UNP} unpushed commit(s)"
  [ "$HRS" -ge "$FLOOR_HOURS" ] && REASONS="${REASONS:+$REASONS, }periodic check (${HRS}h)"
  if [ -z "$REASONS" ]; then
    echo "=== heartbeat silent — no signal $(date) ===" >> "$LOG"
    printf '%s\n%s\n' "$GH" "$LF" > "$GATE"
    exit 0
  fi
else
  REASONS="no git repo (cannot gate cheaply)"
fi

echo "=== heartbeat $(date '+%Y-%m-%d %H:%M:%S') — signals: $REASONS ===" >> "$LOG"
claude -p "Heartbeat triggered. A free pre-gate detected these signals: ${REASONS}. ${PROMPT} Focus on what the signals point to rather than scanning everything." \
  --dangerously-skip-permissions >> "$LOG" 2>&1

# Recompute git hash AFTER the run so the model's own commit doesn't re-trigger next
# beat; this wake counts as a full pass → reset the floor.
if git rev-parse --git-dir >/dev/null 2>&1; then
  printf '%s\n%s\n' "$(git status --porcelain 2>/dev/null | shasum | cut -d' ' -f1)" "$NOW" > "$GATE"
fi

# Cross-device sync: push any memory the heartbeat wrote/distilled (and pull
# remote changes). Fail-safe; no-ops when nothing changed.
"$SCRIPT_DIR/memory_sync.sh" >> "$LOG" 2>&1 || true
