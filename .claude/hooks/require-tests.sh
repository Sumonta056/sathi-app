#!/usr/bin/env bash
set -u
ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$ROOT" || exit 0

INPUT="$(cat)"
[ "$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)" = "true" ] && exit 0

CHANGED="$(git status --porcelain -- Sources Tests Package.swift 2>/dev/null | grep -E '\.swift$' || true)"
[ -z "$CHANGED" ] && exit 0

LINT="$(./scripts/lint.sh 2>&1)"
if [ $? -ne 0 ]; then
  printf 'Swift files changed and lint fails. Fix it before you finish:\n%s\n' "$(printf '%s' "$LINT" | tail -20)" >&2
  exit 2
fi

TEST="$(swift test 2>&1)"
if [ $? -ne 0 ]; then
  SUMMARY="$(printf '%s' "$TEST" | sed 's/\x1b\[[0-9;]*m//g' | grep -E 'error:|✘' | head -25)"
  printf 'Swift files changed and tests fail. Fix them before you finish:\n%s\n' "$SUMMARY" >&2
  exit 2
fi
exit 0
