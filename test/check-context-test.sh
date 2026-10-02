#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
mk() { printf '{"type":"user"}\n{"type":"assistant","message":{"usage":{"input_tokens":%s,"cache_creation_input_tokens":0,"cache_read_input_tokens":0}}}\n' "$1" > "$tmp/$2.jsonl"; }
run() { printf '{"session_id":"%s","transcript_path":"%s/%s.jsonl","stop_hook_active":false}' "$1" "$tmp" "$1" | CLAUDE_PLUGIN_DATA="$tmp" "$here/scripts/check-context.sh"; }
fail() { echo "FAIL: $1"; exit 1; }

mk 170000 big;   out="$(run big)";   echo "$out" | grep -q '"decision": "block"' || fail "no block over the threshold: $out"
out="$(run big)";   [ -z "$out" ] || fail "asked twice in one session"
mk 50000 small;  out="$(run small)"; [ -z "$out" ] || fail "blocked under the threshold"
mk 170000 off;   out="$(ROTATION_DISABLED=1 run off)"; [ -z "$out" ] || fail "ignored ROTATION_DISABLED"
mk 170000 low;   out="$(ROTATION_THRESHOLD_TOKENS=200000 run low)"; [ -z "$out" ] || fail "ignored ROTATION_THRESHOLD_TOKENS"
echo "PASS: blocks once over the threshold; silent under it, when disabled, and with a higher threshold"
