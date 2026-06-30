#!/bin/zsh
# Send a Telegram message via your bot. Usage: tg_notify.sh "message text"
#
# Config: reads TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID from an env file.
# Override the location with HEARTBEAT_ENV; otherwise these are tried in order:
#   $HEARTBEAT_ENV
#   <plugin>/.env                       (written by setup.sh — the canonical config)
#   ~/.claude/channels/telegram/.env    (if you use the official telegram plugin)
#   ~/.config/claude-anima/.env
# NEVER commit this env file — keep token + chat_id out of the repo.
set -e

# Resolve at top level: inside a zsh function $0 is the function name, not the script.
SCRIPT_DIR="${0:A:h}"

_find_env() {
  for f in "$HEARTBEAT_ENV" \
           "$SCRIPT_DIR/../.env" \
           "$HOME/.claude/channels/telegram/.env" \
           "$HOME/.config/claude-anima/.env"; do
    [ -n "$f" ] && [ -f "$f" ] && { echo "$f"; return 0; }
  done
  return 1
}

ENV_FILE="$(_find_env)" || {
  echo "tg_notify: no env file found (set HEARTBEAT_ENV or create ~/.config/claude-anima/.env)" >&2
  exit 1
}
source "$ENV_FILE"

: "${TELEGRAM_BOT_TOKEN:?tg_notify: TELEGRAM_BOT_TOKEN not set in $ENV_FILE}"
: "${TELEGRAM_CHAT_ID:?tg_notify: TELEGRAM_CHAT_ID not set in $ENV_FILE}"
[ -n "$1" ] || { echo "tg_notify: empty message" >&2; exit 1; }

curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -d chat_id="${TELEGRAM_CHAT_ID}" \
  --data-urlencode "text=$1" \
  -d disable_notification=false >/dev/null
