#!/usr/bin/env bash
# SessionStart hook: a session started by rotate.sh reports that it is up, so the old one can close.
cat > /dev/null
[ -n "${CLAUDE_ROTATION_READY:-}" ] && touch "$CLAUDE_ROTATION_READY"
exit 0
