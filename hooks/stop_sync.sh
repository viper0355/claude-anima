#!/usr/bin/env bash
# Stop hook — when memory changed this session, push it (cross-device sync).
# Fast no-op when nothing changed (a local `git status`, no network). When dirty,
# the actual sync runs detached so the turn never waits on the network.
set -uo pipefail

ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

# Resolve MEMORY_DIR (caller wins over .env), same logic as session_start.
_caller_mem="${MEMORY_DIR:-}"
[ -f "$ROOT/.env" ] && { set -a; . "$ROOT/.env"; set +a; }
[ -n "$_caller_mem" ] && MEMORY_DIR="$_caller_mem"
mem_dir="${MEMORY_DIR:-}"
if [ -z "$mem_dir" ]; then
  d="${CLAUDE_PROJECT_DIR:-$PWD}"
  while [ "$d" != "/" ] && [ -n "$d" ]; do
    [ -f "$d/HEARTBEAT.md" ] && { mem_dir="$d"; break; }
    d="$(dirname "$d")"
  done
fi
[ -n "$mem_dir" ] && [ -d "$mem_dir/.git" ] || exit 0

# Nothing changed → fast exit (no network, no delay).
[ -n "$(git -C "$mem_dir" status --porcelain 2>/dev/null)" ] || exit 0

# Dirty → sync detached (don't block the turn). nohup survives session exit.
MEMORY_DIR="$mem_dir" nohup "$ROOT/scripts/memory_sync.sh" >/dev/null 2>&1 &
exit 0
