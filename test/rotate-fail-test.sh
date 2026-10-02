#!/usr/bin/env bash
# If the new session cannot start, the old pane must stay open.
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
s="rotation-fail-$$"
tmp="${TMPDIR:-/tmp}"
printf 'handoff\n' > "$tmp/rotation-handoff.md"
tmux new-session -d -s "$s" -n work -c "$here" \
  "ROTATION_CLAUDE_CMD=false ROTATION_READY_TIMEOUT=5 '$here/scripts/rotate.sh' '$tmp/rotation-handoff.md' > '$tmp/rotation-fail-out' 2>&1; sleep 30"
old="$(tmux list-panes -t "$s" -F '#{pane_id}' | head -1)"
sleep 7
tmux list-panes -s -t "$s" -F '#{pane_id}' | grep -qx "$old" || { echo "FAIL: old pane was closed"; exit 1; }
grep -q "keeping this one" "$tmp/rotation-fail-out" || { echo "FAIL: no clear message"; cat "$tmp/rotation-fail-out"; exit 1; }
tmux kill-session -t "$s"
echo "PASS: failed start keeps the old session ($(cat "$tmp/rotation-fail-out"))"
