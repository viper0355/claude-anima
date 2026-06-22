# claude-heartbeat (WIP)

OpenClaw-style **persistent memory** + **hourly heartbeat** for Claude Code, packaged as a plugin.

> Status: being built autonomously by a heartbeat agent. See BUILD-PLAN.md for progress.

## What it gives any Claude Code project
- **Heartbeat**: launchd wakes a headless Claude hourly (daytime); it rotates through your check-list, does useful background work, and pings you on Telegram only when it matters.
- **Memory system**: OpenClaw-style IDENTITY / USER / SOUL / MEMORY structure + daily notes + periodic distillation, so your AI remembers across sessions and devices.

Inspired by OpenClaw / Hermes. MIT-0.
