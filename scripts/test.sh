#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ $# -gt 0 ]]; then
  swift test --filter "$1"
else
  swift test
fi
