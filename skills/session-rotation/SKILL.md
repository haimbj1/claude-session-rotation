---
name: session-rotation
description: Hand off to a fresh Claude Code session when the context is high - write a handoff file, then (inside tmux) start a new session in the same tmux session and close this one. Use when the session-rotation hook says the context is high, or when the user asks to rotate, hand off, or start a fresh session.
---

# Session rotation

A long session gets slow and forgetful. Rotation moves the work to a fresh session without losing anything:
write a handoff, start the next session, close this one.

## When
- The Stop hook says the context is high, or the user runs `/rotate` or asks to rotate.
- Only between tasks: finish the step in flight and commit or save first. Never rotate mid-edit.

## 1. Write the handoff
Write it to `.handoffs/<YYYY-MM-DD-HHMM>.md` at the project root (create the folder; suggest adding `.handoffs/` to `.gitignore` once). Not under `.claude/`: Claude Code asks before every write there. The next session knows nothing else,
so make it complete and short:

1. **Goal** — what the user wants overall, in their words.
2. **State** — what is done and verified (tests, commits, deploys), with paths and commands.
3. **Next steps** — an ordered list; the first item must be startable without questions.
4. **Decisions and preferences** — what the user decided or asked for in this session (style, tools, things to avoid).
5. **Open questions / waiting on the user** — anything blocked on them.
6. **Pointers** — key files, docs, links, ids. Never secrets: point to where they are stored.

If the project already has a status or handoff file (e.g. `docs/STATUS.md`), update it too and mention it in the handoff.

## 2. Rotate
- **Inside tmux** (`$TMUX` is set): run
  `"${CLAUDE_PLUGIN_ROOT}/scripts/rotate.sh" <handoff-path>`
  It opens a new window in the same tmux session, starts `claude` with a prompt to read the handoff, waits until the new session
  reports ready, then closes this pane. If the new session fails to start, this one stays and the script says why.
- **Outside tmux:** tell the user the handoff is ready and give the path; suggest `/compact`, or a new session started with
  "Continue from <handoff-path>".

## Settings (environment variables)
- `ROTATION_THRESHOLD_TOKENS` — when the hook asks for a rotation (default 160000; raise it for 1M-context models).
- `ROTATION_DISABLED=1` — turn the automatic prompt off.
- `ROTATION_READY_TIMEOUT` — seconds to wait for the new session (default 120).
