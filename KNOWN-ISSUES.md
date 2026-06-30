# Known limitation — Claude Code is multi-session, not a single loop

**This is an architectural difference from OpenClaw / Hermes, not a bug.**

OpenClaw / Hermes run as **one persistent loop**: the heartbeat is that single
process's own pulse, and everything shares one runtime. There is no notion of
"multiple sessions."

Claude Code is different. Each heartbeat wake-up is a **separate headless
`claude` session** (a new process), running **in parallel** with any other
sessions you have open — your interactive session, a long-running `--channels`
bot, background sub-agents, etc.

## The trap: parallel sessions fight over exclusive resources

Every session in a project loads that project's **enabled plugins**, and each
loaded plugin spins up its own MCP server. If a plugin holds an **exclusive,
single-owner resource**, parallel sessions will fight over it.

The concrete case we hit: a **Telegram bot token**. Telegram allows exactly
**one `getUpdates` consumer per token**. If you run a long-lived bidirectional
bot (`claude --channels plugin:telegram@...`) *and* the telegram plugin is
enabled project-wide, then every time the **heartbeat fires on the hour** — or
you **spawn a background agent** — that new session also starts a telegram MCP
server, grabs the same token, and knocks the long-running bot off its
connection.

Symptoms (from the MCP server logs):

```
UNKNOWN connection closed after Ns (cleanly)
Cleared connection cache for reconnection
telegram channel: replacing stale poller pid=XXXX
```

…clustered **on the hour** (heartbeat) and whenever a new session starts. The
bot looks alive (the process is still up) but goes deaf during each reconnect
window, so messages sent then get no reply. It looks like "the bot is flaky"
but the real cause is **resource contention between sessions**.

> Note: claude-anima's own Telegram notify (`tg_notify.sh`) is **one-way**
> (`curl` → `sendMessage`). It does **not** poll `getUpdates`, so it never
> competes. The conflict only arises if you separately run a **bidirectional
> `--channels` bot**.

## Mitigations

1. **Don't enable a bidirectional channel plugin project-wide.** Keep the
   `--channels` bot to its **own dedicated session/working dir**, so heartbeat
   and agent sessions don't load it and don't poll the token.
2. **Use one-way notify for the heartbeat** (`tg_notify.sh`) — it never polls.
3. **Make the heartbeat single-instance** — a lock file so two heartbeat
   sessions can never overlap.

## Verified fix (2026-06-25)

The clean fix keeps the `--channels` bot working while stopping every *other*
session from touching the token. **Both halves are required.**

1. **Disable the channel plugin globally.** In `~/.claude/settings.json`, under
   `enabledPlugins`, set the bidirectional channel plugin to `false`. Now
   heartbeat, sub-agents and interactive sessions never load it, never poll.
2. **Re-enable it for the channels session only, via `--settings`.** Put the
   flag in a tiny file and pass it on the channels launch:
   ```json
   // ~/.claude/channels-telegram.json
   { "enabledPlugins": { "telegram@claude-plugins-official": true } }
   ```
   ```bash
   claude --channels plugin:telegram@claude-plugins-official \
     --settings ~/.claude/channels-telegram.json
   ```
   Only that one session loads the plugin and polls the token.

**Verified** in the author's setup: the channels bot connects and sends/receives
normally; a simulated heartbeat session (no `--settings`) does **not** start the
plugin's MCP server, does not grab the token, and the bot is never interrupted.

⚠️ Disabling globally **without** the `--settings` re-add turns `--channels` into
a dead shell — the plugin's MCP server won't load at all. You need both steps.

# Cross-device memory sync — conflict handling

Memory (`MEMORY_DIR`) is a git repo synced across devices:
- **Pull on session start** (`session_start.sh`, 5s-capped, offline-safe).
- **Push when memory changes** — interactive sessions via the `Stop` hook
  (`stop_sync.sh`, only when dirty), automated beats via `heartbeat.sh`.
- `memory_sync.sh` does `pull --rebase --autostash` → commit → push, single-flight
  (lock at `.git/anima-sync.lock`), and fail-safe (offline never breaks a session).

**Limitation — same-line concurrent edits.** Memory is mostly append/distinct
files, so rebase auto-merges cleanly in practice. If two devices edit the *same
line* before syncing, `pull --rebase` fails and `memory_sync` logs
`pull skipped (offline or conflict)`; the local change stays uncommitted until a
human resolves it. No data is lost, but that file won't sync until resolved.
