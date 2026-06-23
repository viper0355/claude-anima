#!/usr/bin/env bash
# SessionStart hook — inject the agent's persistent memory summary into a fresh session.
# Outputs JSON with hookSpecificOutput.additionalContext so Claude loads memory on wake.
#
# MEMORY_DIR resolution order:
#   1. $MEMORY_DIR (set in .env / by setup.sh)
#   2. directory containing HEARTBEAT.md, searched up from $CLAUDE_PROJECT_DIR
#   3. silently no-op (emit nothing) if no memory workspace is found
#
# SECURITY: MEMORY.md holds personal context. It is loaded ONLY here (the main
# session). The memory skill forbids loading it in shared/group contexts.
set -euo pipefail

ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

# 1. Load .env next to the plugin if present (non-fatal).
if [ -f "$ROOT/.env" ]; then
  set -a; . "$ROOT/.env"; set +a
fi

# 2. Resolve memory dir.
mem_dir="${MEMORY_DIR:-}"
if [ -z "$mem_dir" ]; then
  d="${CLAUDE_PROJECT_DIR:-$PWD}"
  while [ "$d" != "/" ] && [ -n "$d" ]; do
    if [ -f "$d/HEARTBEAT.md" ]; then mem_dir="$d"; break; fi
    d="$(dirname "$d")"
  done
fi

# No workspace → emit nothing, exit clean (don't disturb non-memory projects).
[ -n "$mem_dir" ] && [ -d "$mem_dir" ] || exit 0

# 3. Concatenate the always-load memory files that exist.
buf=""
for f in IDENTITY.md USER.md SOUL.md MEMORY.md; do
  if [ -f "$mem_dir/$f" ]; then
    buf+=$'\n\n===== '"$f"$' =====\n'
    buf+="$(cat "$mem_dir/$f")"
  fi
done

[ -n "$buf" ] || exit 0

intro=$'Your persistent memory (load fresh each session — these files are your continuity):'
context="$intro$buf"

# 4. Emit as SessionStart additionalContext (JSON-escaped via jq, fallback to python).
if command -v jq >/dev/null 2>&1; then
  jq -n --arg c "$context" \
    '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$c}}'
else
  python3 - "$context" <<'PY'
import json,sys
print(json.dumps({"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":sys.argv[1]}}))
PY
fi
