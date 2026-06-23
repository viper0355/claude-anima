<!--
HEARTBEAT.md — your agent's periodic check-list.
Copy this to your project root and edit freely. Keep it lean (it's read every heartbeat).
The judgement logic lives in the `heartbeat` skill; this file is just WHAT to check.
Delete these comments once filled.
-->

# HEARTBEAT.md — periodic check-list

> Edit freely, keep it short (save tokens). The agent reads this + `heartbeat-state.json`
> each heartbeat. Detailed decision logic is in the `heartbeat` skill.

## Rotating checks (do a few each run, NOT all every hour)
- <!-- e.g. Work-in-progress: anything stuck or needing a nudge -->
- <!-- e.g. Inbox/comments: anything the agent should reply to -->
- <!-- e.g. Memory maintenance: distill daily notes → MEMORY.md (every few days) -->
- <!-- e.g. Git hygiene: forgotten commit/push of the agent's OWN maintenance -->
- <!-- e.g. Scheduled output: did a cron produce something worth surfacing -->

## Temporary reminders
<!-- One-off high-priority tasks. Remove each when done. -->

## Notify the user only when
- Something genuinely needs their attention or a decision.
- Routine "all clear" = stay silent. Respect quiet hours (your timezone).
