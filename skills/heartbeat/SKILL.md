---
name: heartbeat
description: Hourly heartbeat for your agent. Wake, rotate through your project's checks, do useful background work, and notify the user via Telegram ONLY when something genuinely needs their attention. Triggered by launchd/cron (daytime, hourly) or manually ("run a heartbeat").
---

# Heartbeat

You were woken by a heartbeat (launchd/cron, hourly daytime — or a manual request). You are this project's agent, checking in. **Core rule: be useful without being annoying.** Most heartbeats should end silently.

> Config lives outside this skill. The values below come from the user's setup, NOT hardcoded here:
> - `$HEARTBEAT_DIR` — project root (where `HEARTBEAT.md` and `heartbeat-state.json` live). Set in `.env` / by `setup.sh`.
> - Telegram credentials (`TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`) — read from `.env` by `tg_notify.sh`, never written in this file.
> - Project-specific checks, identity, and quiet hours — defined in the user's `HEARTBEAT.md`.

## Steps

1. **Read state**: `HEARTBEAT.md` (task checklist + the project's own check definitions) and `heartbeat-state.json` (last-check timestamps). Get current local time.
2. **Quiet hours**: if within the quiet window defined in `HEARTBEAT.md` (default 23:00–08:00 local), exit immediately unless something is truly urgent. Do not notify.
3. **Rotate checks** — do NOT run every check every hour. Pick the ones whose `lastChecks` timestamp is stale (e.g. >4h), batch them in one pass. The concrete checks are listed in the user's `HEARTBEAT.md`; common ones:
   - **Work progress** — scan the project for stuck or pending todos worth nudging.
   - **Git hygiene** — uncommitted or unpushed work left behind (run `git status`).
   - **Memory maintenance** — every few days, distill recent daily notes into the memory index; prune stale entries.
   - **Scheduled output** — did any cron/scheduled job produce something the user should actually see.
4. **Decide**: notify the user ONLY if something genuinely needs their attention or decision. Routine "all clear" = stay silent.
5. **Notify** (when warranted): `bash "$HEARTBEAT_DIR/scripts/tg_notify.sh" "<short message>"`. Keep it one tight paragraph; they read it on their phone.
6. **Update** `heartbeat-state.json` with this run's checks + timestamps.

## Stay silent (no Telegram) when
- Nothing new since the last check
- You checked that item <30 min ago
- It's quiet hours
- The work is routine and needs no decision from the user

## Never do autonomously (notify the user instead)
- **Do NOT commit/push work products** if your project follows a `draft → review → final` flow. If you spot uncommitted work, **NOTIFY the user, don't commit it.** (Adjust this rule in `HEARTBEAT.md` if your project wants auto-commit.)
- **Do NOT take irreversible or outward-facing actions** (publishing, posting, sending, deleting). Surface them for the user to decide.
- You MAY commit only your **own maintenance**: `heartbeat-state.json`, the memory index distillation.

## Token economy
Each heartbeat is a fresh headless session that costs API. So: check only what's stale, batch into one pass, do the useful background work (commit, tidy memory), and exit fast. A silent heartbeat should be cheap.
