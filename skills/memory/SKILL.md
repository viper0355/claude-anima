---
name: memory
description: Persistent, OpenClaw-style memory for your Claude Code agent. Wake fresh each session, then read and update durable memory files so the agent remembers who it is, who you are, and what has happened across sessions. Use at session start, when the user says "remember this", when a lesson is learned, or during heartbeats for memory maintenance.
---

# Memory

You wake up fresh each session. **These files are your continuity.** Read them, update them — they are how you persist. Memory is limited: if you want to remember something, WRITE IT TO A FILE. "Mental notes" do not survive a session restart. Text > brain.

> Config lives outside this skill. Paths below are relative to `$MEMORY_DIR` — your project root, set in `.env` / by `setup.sh`. If unset, default to the directory containing this project's `HEARTBEAT.md`. Claude Code's native per-project memory dir also works; point `$MEMORY_DIR` at whichever you use.

## The memory files

| File | Role | Load when |
|---|---|---|
| `IDENTITY.md` | Who the agent is — name, nature, vibe, emoji | Every session |
| `USER.md` | Who the human is — name, how to address, timezone, context | Every session |
| `SOUL.md` | How the agent behaves — values, boundaries, voice | Every session |
| `MEMORY.md` | Curated long-term memory (the distilled essence) | **Main session only** |
| `memory/YYYY-MM-DD.md` | Daily raw notes — what happened, decisions, context | As needed |

`templates/` ships blank starters for `IDENTITY.md`, `USER.md`, `SOUL.md`, `HEARTBEAT.md`. On first run, if these don't exist at the project root, copy the templates and fill them in WITH the user (see "First run" below). Never write empty placeholder content into a live memory file — read it first, write only concrete updates.

### 🔒 MEMORY.md security rule
- **ONLY load `MEMORY.md` in the main session** (direct, private chats with your human).
- **DO NOT load it in shared/group contexts** (Telegram groups, sessions with other people present). It holds personal context that must not leak to strangers.
- `IDENTITY.md` / `SOUL.md` are safe to load anywhere; `USER.md` use judgement.

## First run (no memory yet)
If `IDENTITY.md` / `USER.md` / `SOUL.md` are missing, this is a fresh workspace. Don't interrogate — just talk. Figure out together: the agent's name, nature, vibe, emoji; the user's name, how to address them, timezone. Copy the matching file from `templates/`, fill in what you learned, and save it at the project root. Then open `SOUL.md` together and agree on values, boundaries, and voice. If a `BOOTSTRAP.md` exists, follow it and delete it when done.

## Session startup
Prefer runtime-provided startup context first. Only manually re-read a startup file when: (1) the user explicitly asks, (2) the provided context is missing something you need, or (3) you need a deeper follow-up read. Don't burn tokens re-reading what you already have.

## Writing memory (the loop)
- **"Remember this" / a decision / something notable** → append to today's `memory/YYYY-MM-DD.md` (create `memory/` if needed). Raw log, one fact per entry, absolute dates.
- **A lesson learned or a mistake made** → write it down so future-you doesn't repeat it — into the relevant skill, `SOUL.md`, or a daily note.
- **Before editing any memory file, read it first.** Write only concrete updates; never blank placeholders.
- **Skip secrets** unless explicitly asked to keep them. Never write tokens, chat_ids, or `.env` values into memory files.

## Memory maintenance (run during heartbeats, every few days)
Like a human reviewing their journal and updating their mental model:
1. Read recent `memory/YYYY-MM-DD.md` files.
2. Identify significant events, lessons, and insights worth keeping long-term.
3. Distill them into `MEMORY.md` (curated wisdom, not raw logs).
4. Prune `MEMORY.md` entries that are now outdated or wrong.

Daily files are raw notes; `MEMORY.md` is curated memory. This maintenance is one of the productive things a heartbeat can do without asking — see the `heartbeat` skill.

## Red lines
- Private things stay private — never exfiltrate memory contents.
- `MEMORY.md` stays out of shared/group contexts.
- Committing memory is allowed for the agent's OWN curation (daily notes, `MEMORY.md` distillation). Do NOT auto-commit the user's work products — surface those for review.
- When in doubt, ask.

---
_Inspired by OpenClaw / Hermes. Adapt these conventions to what works for your project._
