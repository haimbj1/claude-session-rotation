#!/usr/bin/env bash
# Rotates a Claude Code session inside tmux: starts a fresh `claude` in a new window of the same
# tmux session, waits until it reports ready (SessionStart hook), then closes the old pane.
# The old session must have written its handoff first; the new one is told to read it.
#
#   rotate.sh <handoff-file>
#
# Env: ROTATION_READY_TIMEOUT (seconds, default 120), ROTATION_CLAUDE_CMD (default "claude").
set -euo pipefail

handoff="${1:?usage: rotate.sh <handoff-file>}"
[ -n "${TMUX:-}" ] || { echo "rotate: not inside tmux; nothing to rotate into." >&2; exit 1; }
[ -n "${TMUX_PANE:-}" ] || { echo "rotate: TMUX_PANE is not set." >&2; exit 1; }
[ -f "$handoff" ] || { echo "rotate: handoff file not found: $handoff" >&2; exit 1; }

old_pane="$TMUX_PANE"
cwd="${CLAUDE_PROJECT_DIR:-$PWD}"
timeout="${ROTATION_READY_TIMEOUT:-120}"
claude_cmd="${ROTATION_CLAUDE_CMD:-claude}"
ready="${TMPDIR:-/tmp}/claude-rotation-$(date +%s)-$$.ready"
abs_handoff="$(cd "$(dirname "$handoff")" && pwd)/$(basename "$handoff")"
prompt="This session continues a previous one. Read the handoff at ${abs_handoff} first, then continue from its next steps."
window_name="$(tmux display-message -p -t "$old_pane" '#W')"

new_pane="$(tmux new-window -P -F '#{pane_id}' -n "$window_name" -c "$cwd" \
  -e "CLAUDE_ROTATION_READY=$ready" -e "CLAUDE_ROTATION_FROM=$old_pane" \
  "$claude_cmd $(printf '%q' "$prompt")")"

for _ in $(seq 1 "$timeout"); do
  [ -f "$ready" ] && break
  # The new pane died (claude failed to start): keep the old session.
  tmux list-panes -a -F '#{pane_id}' | grep -qx "$new_pane" || { echo "rotate: the new session exited; keeping this one." >&2; exit 1; }
  sleep 1
done
[ -f "$ready" ] || { echo "rotate: the new session did not report ready in ${timeout}s; keeping this one (new window: $new_pane)." >&2; exit 1; }
rm -f "$ready"

tmux select-window -t "$new_pane"
# Close the old pane a moment later, so this script can report back first.
tmux run-shell -b "sleep 2; tmux kill-pane -t '$old_pane'"
echo "rotate: new session is up in $new_pane; closing $old_pane."
