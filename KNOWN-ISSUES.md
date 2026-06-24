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

> Note: claude-heartbeat's own Telegram notify (`tg_notify.sh`) is **one-way**
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

(Root cause confirmed 2026-06-24 in the author's own setup. The exact isolation
recipe will be finalized here once the fix is verified in production.)
