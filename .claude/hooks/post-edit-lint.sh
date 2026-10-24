#!/usr/bin/env bash
set -u
ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$ROOT" || exit 0

FILE="$(jq -r '.tool_input.file_path // .tool_response.filePath // empty' 2>/dev/null)"
[ -z "$FILE" ] && exit 0
case "$FILE" in /*) ;; *) FILE="$ROOT/$FILE" ;; esac
case "$FILE" in "$ROOT"/Sources/*.swift|"$ROOT"/Tests/*.swift) ;; *) exit 0 ;; esac
[ -f "$FILE" ] || exit 0
REL="${FILE#"$ROOT"/}"
MAX_LINES=200

command -v swiftformat >/dev/null 2>&1 && swiftformat "$REL" --quiet >/dev/null 2>&1

if command -v swiftlint >/dev/null 2>&1; then
  OUT="$(swiftlint lint --quiet --strict "$REL" 2>&1)"
  if [ -n "$OUT" ]; then
    printf 'SwiftLint problems in %s. Fix them:\n%s\n' "$REL" "$OUT" >&2
    exit 2
  fi
fi

LINES="$(wc -l < "$FILE" | tr -d ' ')"
if [ "$LINES" -gt "$MAX_LINES" ]; then
  printf '%s has %s lines (max %s). Split it by job into files in the same folder.\n' "$REL" "$LINES" "$MAX_LINES" >&2
  exit 2
fi
exit 0
