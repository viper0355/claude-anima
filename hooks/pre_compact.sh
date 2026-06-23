#!/usr/bin/env bash
# PreCompact hook — fires before Claude compacts/summarizes the conversation,
# the moment when raw context is about to be lost. A hook can't do the writing
# itself, so it injects a reminder telling the agent to flush anything worth
# keeping into durable memory (today's memory/YYYY-MM-DD.md) BEFORE compaction.
#
# Output: plain text on stdout becomes context the agent sees. Keep it short.
set -euo pipefail

cat <<'EOF'
[memory] About to compact — context is about to be summarized away. Before it is:
persist anything durable (decisions, lessons, open threads, facts to remember)
into today's memory/YYYY-MM-DD.md per the `memory` skill. Mental notes won't
survive compaction; text > brain. Skip secrets/tokens.
EOF
