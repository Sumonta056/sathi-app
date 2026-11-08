#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ $# -eq 0 ]]; then
  swift test
  exit
fi

LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT
status=0
swift test --filter "$1" 2>&1 | tee "$LOG" || status=$?
if grep -q "No matching test cases were run" "$LOG"; then
  echo "FAIL: filter '$1' matched 0 tests. Use the type name (e.g. HabitCardGoalMetTests) or a test target." >&2
  exit 1
fi
exit "$status"
