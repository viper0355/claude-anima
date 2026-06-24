# BUILD-PLAN — claude-heartbeat plugin

> AUTONOMOUS build. Each heartbeat: pick the next unchecked step, do ONE step, `git add -A && git commit`, check it off. Keep it cheap. NEVER commit secrets — use placeholders.
> Goal: a GENERIC, open-source Claude Code PLUGIN giving any project (1) OpenClaw-style memory, (2) hourly heartbeat + Telegram notify. Strip ALL yt-channel / Piko / Hank-specific values into config + templates.

## Reference sources (copy from these, then generalize)
- Heartbeat skill: ~/yt-channel/.claude/skills/heartbeat/SKILL.md
- Notify: ~/yt-channel/automation/tg_notify.sh
- Trigger: ~/yt-channel/automation/heartbeat.sh + com.hank.yt.heartbeat.plist
- Data: ~/yt-channel/HEARTBEAT.md + automation/heartbeat-state.json
- Real plugin manifest example: ~/.claude/plugins/marketplaces/claude-plugins-official/external_plugins/telegram/.claude-plugin/plugin.json
- OpenClaw memory model (concept reference, do NOT copy verbatim): "~/Documents/AI Agent/openclaw-youtube/"{AGENTS,IDENTITY,USER,SOUL,HEARTBEAT,BOOTSTRAP}.md

## Steps (ONE per heartbeat, commit after each)
- [x] 0. Scaffold dirs + .gitignore + plugin.json stub + README stub  (done by setup session)
- [x] 1. skills/heartbeat/SKILL.md: copy from yt-channel, GENERALIZE — replace hardcoded chat_id / yt-channel paths / Piko identity / channel-specific checks with generic placeholders that point at the user's HEARTBEAT.md + config.
- [x] 2. scripts/tg_notify.sh: generalize — read chat_id from .env/config, not hardcoded.
- [x] 3. scripts/heartbeat.sh + templates/heartbeat.plist.template: project path via env var; template the user fills in.
- [x] 4. skills/memory/SKILL.md: OpenClaw-style memory SOP adapted to Claude Code's native memory dir (IDENTITY/USER/SOUL/MEMORY + daily notes + distillation).
- [x] 5. templates/: IDENTITY.md, USER.md, SOUL.md, HEARTBEAT.md starter templates (blank + instructions).
- [x] 6. hooks/: SessionStart loads memory (IDENTITY/USER/SOUL/MEMORY → additionalContext) + PreCompact reminds agent to flush durable memory before compaction. Wired via plugin.json `hooks: ./hooks/hooks.json`. MEMORY_DIR resolves from .env or by walking up to HEARTBEAT.md; silent no-op outside memory workspaces. Tested both scripts.
- [x] 7. scripts/setup.sh: idempotent installer — prompts for bot token + chat_id + project/memory dir + waking hours, writes gitignored .env (chmod 600), seeds memory+HEARTBEAT templates (never clobbers), installs+loads per-user launchd agent (cron fallback off-mac), sends a test Telegram. bash -n clean.
- [x] 8. README.md: full — what it is, /plugin install, setup, config, safety. Credit OpenClaw/Hermes.
- [x] 9. marketplace.json so it can be /plugin install'd.
- [x] 10. Final self-review: confirmed NO hardcoded secrets — `.env`/bot token/chat_id all gitignored; only `viper0355` (Hank's public GitHub handle, intended as plugin author/homepage) appears in manifests. Notified Hank, removed build task from yt-channel HEARTBEAT.md. BUILD COMPLETE.

## Notes from heartbeat runs (append below)

## Future (post-launch)
- **User-configurable heartbeat frequency + minimal per-wake token cost.** Adoption hinges on this — if the heartbeat is expensive, nobody runs it. Each wake should do as little as possible (read state, decide, exit if nothing to do).
- **Schedule profiles by routine/day.** e.g. weekday: start 08:00, throttle or pause late afternoon to leave quota for the user's evening; weekend a separate profile. Driven by the user's real working hours.
