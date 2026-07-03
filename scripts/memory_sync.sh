#!/bin/zsh
# memory_sync.sh — keep the private memory repo (MEMORY_DIR) in sync across devices.
#   Pull latest → commit any local changes → push. No-ops when nothing changed.
#   Fail-safe: never hard-fails on network errors (won't break a heartbeat/session).
#
# MEMORY_DIR resolution: $MEMORY_DIR env, else $1, else sourced from the plugin .env.
export PATH="/opt/homebrew/bin:$HOME/.local/bin:$PATH"
set -uo pipefail

SCRIPT_DIR="${0:A:h}"
[ -z "${MEMORY_DIR:-}" ] && [ -f "$SCRIPT_DIR/../.env" ] && { set -a; source "$SCRIPT_DIR/../.env"; set +a; }
MEM="${MEMORY_DIR:-${1:-}}"
[ -n "$MEM" ] && [ -d "$MEM/.git" ] || { echo "memory_sync: no git repo at MEMORY_DIR='$MEM'"; exit 0; }
cd "$MEM" || exit 0

# Single-flight: skip if another sync is already running (avoid git half-states).
# Steal the lock if it's stale (>10 min = a crashed sync), otherwise a crash would
# leave the lock behind forever and silently stop all future syncs.
LOCK="$MEM/.git/anima-sync.lock"
if ! mkdir "$LOCK" 2>/dev/null; then
  if [ -d "$LOCK" ] && [ $(( $(date +%s) - $(stat -f %m "$LOCK" 2>/dev/null || date +%s) )) -gt 600 ]; then
    rmdir "$LOCK" 2>/dev/null
    mkdir "$LOCK" 2>/dev/null || { echo "memory_sync: lock contended, skipping"; exit 0; }
    echo "memory_sync: stole stale lock"
  else
    echo "memory_sync: another sync in progress, skipping"; exit 0
  fi
fi
trap 'rmdir "$LOCK" 2>/dev/null' EXIT INT TERM

# 1) Pull latest first (rebase local on top; autostash uncommitted). Fail-safe.
# On conflict, abort the half-done rebase so we never commit into a broken state.
git pull --rebase --autostash --quiet 2>/dev/null || {
  git rebase --abort 2>/dev/null
  echo "memory_sync: pull skipped (offline or conflict)"
}

# 2) Commit local changes if any.
if [ -n "$(git status --porcelain)" ]; then
  git add -A
  git -c commit.gpgsign=false commit -q -m "memory: sync $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo "memory_sync: committed local changes"
fi

# 3) Push if we have unpushed commits. Fail-safe.
if [ -n "$(git log --branches --not --remotes --oneline 2>/dev/null)" ]; then
  git push --quiet 2>/dev/null && echo "memory_sync: pushed" || echo "memory_sync: push failed (offline?)"
else
  echo "memory_sync: nothing to push"
fi
