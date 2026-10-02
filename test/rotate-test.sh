#!/usr/bin/env bash
# End-to-end: a pane runs rotate.sh; expect a new window with the same name and the old pane gone.
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
s="rotation-test-$$"
tmp="${TMPDIR:-/tmp}"
printf 'handoff\n' > "$tmp/rotation-handoff.md"
rm -f "$tmp/rotation-test-prompt" "$tmp/rotation-test-out"
tmux new-session -d -s "$s" -n work -c "$here" \
  "ROTATION_CLAUDE_CMD='$here/test/fake-claude.sh' '$here/scripts/rotate.sh' '$tmp/rotation-handoff.md' > '$tmp/rotation-test-out' 2>&1; sleep 30"
old="$(tmux list-panes -t "$s" -F '#{pane_id}' | head -1)"
for _ in $(seq 1 20); do
  panes="$(tmux list-panes -s -t "$s" -F '#{pane_id} #{window_name}' 2>/dev/null || true)"
  if [ "$(echo "$panes" | wc -l | tr -d ' ')" = 1 ] && ! echo "$panes" | grep -q "^$old "; then break; fi
  sleep 1
done
fail() { echo "FAIL: $1"; echo "panes: $panes"; cat "$tmp/rotation-test-out" 2>/dev/null; tmux kill-session -t "$s" 2>/dev/null; exit 1; }
echo "$panes" | grep -q "^$old " && fail "old pane still open"
echo "$panes" | grep -q " work$" || fail "new window lost the name"
grep -q "rotation-handoff.md" "$tmp/rotation-test-prompt" || fail "new session was not told about the handoff"
tmux kill-session -t "$s"
echo "PASS: rotated $old → $(echo "$panes" | cut -d' ' -f1), name kept, handoff passed"
