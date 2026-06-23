#!/bin/zsh
# Launchd-invoked heartbeat: wake a headless Claude to run the heartbeat skill.
# Configure via .env in the plugin dir or env vars (see templates/heartbeat.plist.template).
#   CLAUDE_HEARTBEAT_PROJECT_DIR  — project to run the heartbeat in (default: $HOME)
#   CLAUDE_HEARTBEAT_LOG          — log file (default: <project>/heartbeat.log)
#   CLAUDE_HEARTBEAT_PROMPT       — prompt to send (default: run the heartbeat skill)
export PATH="/opt/homebrew/bin:$HOME/.local/bin:$PATH"

# Load .env next to this script if present (KEY=VALUE lines).
SCRIPT_DIR="${0:A:h}"
[ -f "$SCRIPT_DIR/../.env" ] && set -a && source "$SCRIPT_DIR/../.env" && set +a

PROJECT_DIR="${CLAUDE_HEARTBEAT_PROJECT_DIR:-$HOME}"
LOG="${CLAUDE_HEARTBEAT_LOG:-$PROJECT_DIR/heartbeat.log}"
PROMPT="${CLAUDE_HEARTBEAT_PROMPT:-Run a heartbeat now using the heartbeat skill.}"

cd "$PROJECT_DIR" || exit 1
echo "=== heartbeat $(date '+%Y-%m-%d %H:%M:%S') ===" >> "$LOG"
claude -p "$PROMPT" --dangerously-skip-permissions >> "$LOG" 2>&1
