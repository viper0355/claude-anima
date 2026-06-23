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
- [ ] 3. scripts/heartbeat.sh + templates/heartbeat.plist.template: project path via env var; template the user fills in.
- [ ] 4. skills/memory/SKILL.md: OpenClaw-style memory SOP adapted to Claude Code's native memory dir (IDENTITY/USER/SOUL/MEMORY + daily notes + distillation).
- [ ] 5. templates/: IDENTITY.md, USER.md, SOUL.md, HEARTBEAT.md starter templates (blank + instructions).
- [ ] 6. hooks/: SessionStart (load memory summary) + PreCompact (write summary). Research Claude Code hook format first; if unsure, leave a documented stub + NOTE here for Hank.
- [ ] 7. scripts/setup.sh: idempotent installer — prompts for bot token + chat_id + project path, writes .env, installs launchd, copies skills.
- [ ] 8. README.md: full — what it is, /plugin install, setup, config, safety. Credit OpenClaw/Hermes.
- [ ] 9. marketplace.json so it can be /plugin install'd.
- [ ] 10. Final self-review: confirm NO hardcoded secrets/personal values. Then Telegram Hank: "claude-heartbeat build complete, ready for review", and remove the build task from ~/yt-channel/HEARTBEAT.md.

## Notes from heartbeat runs (append below)
