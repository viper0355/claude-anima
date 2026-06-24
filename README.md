# claude-heartbeat

**Persistent memory + a self-scheduling heartbeat for Claude Code.**

Your AI wakes itself on a schedule, rotates through a checklist you define, does
useful background work, and pings you on Telegram **only when something actually
needs you** — then remembers what it learned across sessions and devices.

Inspired by [OpenClaw](https://github.com/OpenClaw) / Hermes. Licensed MIT-0.

---

## What you get

| Piece | What it does |
|---|---|
| **Heartbeat** | A per-user launchd agent (macOS) wakes a headless Claude on a schedule (hourly, daytime by default). It reads your `HEARTBEAT.md` checklist, works through the stale items, and notifies you on Telegram only when warranted. |
| **Memory** | OpenClaw-style `IDENTITY` / `USER` / `SOUL` / `MEMORY` structure plus daily notes and periodic distillation, so your agent keeps context across sessions. |
| **Hooks** | `SessionStart` loads your memory into context automatically; `PreCompact` reminds the agent to flush durable memory before the conversation is compacted. |
| **Telegram notify** | `tg_notify.sh` sends a one-line message via the Telegram Bot API, reading the bot token + chat id from a gitignored `.env`. |

---

## Install

```
/plugin install claude-heartbeat
```

Then run the one-time setup from the plugin root:

```
bash scripts/setup.sh
```

`setup.sh` is idempotent — it prompts for:

- **Telegram bot token + chat id** (for notifications)
- **Project / memory directory** (where `HEARTBEAT.md` and memory live)
- **Waking hours** (so it stays quiet overnight)

…then writes a gitignored `.env` (chmod 600), seeds the memory + `HEARTBEAT.md`
templates **without clobbering** anything you already have, installs and loads
the per-user launchd agent (with a cron fallback off macOS), and sends a test
Telegram message so you can confirm the wiring.

---

## Configure

- **`HEARTBEAT.md`** (in your project) — the checklist the heartbeat rotates
  through. Keep it short; each line is a thing to check. Edit freely.
- **`.env`** — bot token, chat id, project/memory dir, waking hours. Never
  committed.
- **`templates/`** — starter `IDENTITY.md`, `USER.md`, `SOUL.md`, `HEARTBEAT.md`
  you can copy and fill in.
- **launchd schedule** — edit the installed agent (or re-run `setup.sh`) to
  change cadence or waking hours.

The heartbeat skill resolves your memory dir from `.env`, or by walking up the
tree to find `HEARTBEAT.md`. Outside a memory workspace the hooks are a silent
no-op, so installing the plugin never interferes with unrelated projects.

---

## Safety

- **Secrets stay local.** The bot token and chat id live only in the gitignored
  `.env` (chmod 600). `.gitignore` also excludes `*.log` and
  `heartbeat-state.json`. Nothing personal is committed.
- **The heartbeat is conservative by default.** It notifies you only when
  something needs a decision; routine "all clear" runs stay silent.
- **It won't take irreversible actions on its own** unless your `HEARTBEAT.md`
  explicitly tells it to — the default posture is "surface it, let the human
  decide."
- Review `HEARTBEAT.md` before enabling: anything you list there is something the
  agent may act on unattended.

---

## Layout

```
.claude-plugin/plugin.json   plugin manifest (wires hooks)
hooks/                       session_start.sh, pre_compact.sh, hooks.json
scripts/                     heartbeat.sh, tg_notify.sh, setup.sh
skills/heartbeat/            the heartbeat SOP (SKILL.md)
skills/memory/               the memory SOP (SKILL.md)
templates/                   IDENTITY / USER / SOUL / HEARTBEAT starters + plist template
```

---

## Credits

Memory model and heartbeat concept inspired by **OpenClaw / Hermes**. Built and
maintained autonomously by a heartbeat agent. MIT-0 — do what you like, no
attribution required.
