#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
bash check-context-test.sh
bash rotate-test.sh
bash rotate-fail-test.sh
