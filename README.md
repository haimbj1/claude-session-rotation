# session-rotation

A Claude Code plugin. When a session's context gets high, Claude writes a handoff and continues in a **fresh session
in the same tmux session** — the new one starts, reads the handoff, and only then the old one closes.

## How it works
1. **Stop hook** — after each Claude turn, reads the token usage of the latest answer from the session transcript.
   Past the threshold (default 160,000 tokens), it asks Claude, once per session, to hand off.
2. **Handoff** — Claude finishes what is in flight and writes `.handoffs/<date-time>.md`: goal, state, next steps,
   decisions, open questions, pointers (never secrets).
3. **Rotate** (inside tmux) — `scripts/rotate.sh` opens a new window in the same tmux session, starts `claude` with
   "read the handoff first", waits for the new session's **SessionStart** hook to report ready, keeps the window name,
   and closes the old pane. If the new session fails to start, the old one stays.
   The new session gets the same `CLAUDE_CONFIG_DIR` (account/profile) and `ROTATION_*` settings as the old one.
4. **Outside tmux** — Claude gives you the handoff path and suggests `/compact` or a new session.

Rotate by hand any time with **`/rotate`**.

## Install
```bash
claude plugin marketplace add haimbj1/claude-session-rotation
claude plugin install session-rotation@session-rotation
```
Then restart Claude Code (or `/reload-plugins`). Requirements: `python3`; `tmux` for in-place rotation.

## Settings (environment variables)
| Variable | Default | Meaning |
|---|---|---|
| `ROTATION_THRESHOLD_TOKENS` | `160000` | When to ask for a handoff. Raise it for 1M-context models. |
| `ROTATION_DISABLED` | unset | `1` turns the automatic prompt off (`/rotate` still works). |
| `ROTATION_READY_TIMEOUT` | `120` | Seconds to wait for the new session before giving up. |

Tip: add `.handoffs/` to your `.gitignore`.

## Tests
`./test/run-all.sh` — unit test for the context check, plus end-to-end tmux rotation (success and failure) with a fake `claude`.
