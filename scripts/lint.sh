#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

MAX_LINES=200

if [[ "${1:-}" == "--fix" ]]; then
  swiftformat Sources Tests --quiet
  swiftlint --fix --quiet
fi

swiftformat Sources Tests --lint --quiet
swiftlint --strict --quiet

LONG="$(find Sources Tests -name '*.swift' -exec wc -l {} + | awk -v max="$MAX_LINES" '$2 != "total" && $1 > max')"
if [[ -n "$LONG" ]]; then
  echo "Files over $MAX_LINES lines (split them into modules):"
  echo "$LONG"
  exit 1
fi
echo "Lint OK"
