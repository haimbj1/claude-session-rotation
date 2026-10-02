#!/usr/bin/env bash
# Stop hook: once per session, when the context passes the threshold, asks Claude to hand off and rotate.
# Reads the hook JSON on stdin (needs transcript_path, session_id). Prints nothing below the threshold.
# Env: ROTATION_THRESHOLD_TOKENS (default 160000), ROTATION_DISABLED=1 to turn it off.
set -euo pipefail
[ "${ROTATION_DISABLED:-0}" = "1" ] && exit 0
input="$(cat)"
exec python3 - "$input" <<'PY'
import json, os, sys, tempfile

hook = json.loads(sys.argv[1])
if hook.get("stop_hook_active"):          # we already blocked once in this stop cycle
    sys.exit(0)
threshold = int(os.environ.get("ROTATION_THRESHOLD_TOKENS", "160000"))
session = hook.get("session_id", "unknown")
marker = os.path.join(os.environ.get("CLAUDE_PLUGIN_DATA") or tempfile.gettempdir(), f"rotation-nudged-{session}")
if os.path.exists(marker):
    sys.exit(0)

# Context size = what the model read for its latest answer (uncached + cached input).
used = 0
try:
    with open(hook["transcript_path"]) as f:
        for line in f:
            d = json.loads(line)
            u = (d.get("message") or {}).get("usage") if d.get("type") == "assistant" else None
            if u:
                used = u.get("input_tokens", 0) + u.get("cache_creation_input_tokens", 0) + u.get("cache_read_input_tokens", 0)
except (OSError, KeyError, ValueError) as e:
    print(f"session-rotation: could not read the transcript ({e}); skipping", file=sys.stderr)
    sys.exit(0)
if used < threshold:
    sys.exit(0)

os.makedirs(os.path.dirname(marker), exist_ok=True)
open(marker, "w").close()
in_tmux = bool(os.environ.get("TMUX"))
next_step = (
    "then run the session-rotation skill's rotate step (the plugin's scripts/rotate.sh with the handoff path) so a fresh session continues in this tmux session."
    if in_tmux else
    "then tell the user the handoff is ready and suggest /compact or a new session (not inside tmux, so automatic rotation is off)."
)
print(json.dumps({
    "decision": "block",
    "reason": f"Context is high ({used:,} tokens, threshold {threshold:,}). Finish only what is in flight, write a handoff following the session-rotation skill, {next_step}",
}))
PY
