#!/usr/bin/env bash
# Stands in for `claude` in tests: records the prompt, reports ready like the SessionStart hook would, then idles.
printf '%s' "$1" > "${TMPDIR:-/tmp}/rotation-test-prompt"
printf '%s' "${CLAUDE_CONFIG_DIR:-}" > "${TMPDIR:-/tmp}/rotation-test-config"
[ -n "${CLAUDE_ROTATION_READY:-}" ] && touch "$CLAUDE_ROTATION_READY"
sleep 30
