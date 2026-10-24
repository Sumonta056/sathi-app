#!/bin/bash
set -euo pipefail

MAX_CPU="${MAX_CPU:-1.0}"
MAX_FOOTPRINT_MB="${MAX_FOOTPRINT_MB:-40}"
MAX_WAKEUPS_PER_MIN="${MAX_WAKEUPS_PER_MIN:-10}"
SECONDS_TO_SAMPLE="${SECONDS_TO_SAMPLE:-30}"

PID="$(pgrep -x Sathi || true)"
if [[ -z "$PID" ]]; then
  echo "Sathi is not running. Start it with: open /Applications/Sathi.app"
  exit 2
fi

echo "Sampling Sathi (pid $PID) for ${SECONDS_TO_SAMPLE}s…"
LINE="$(top -l 2 -s "$SECONDS_TO_SAMPLE" -pid "$PID" -stats pid,cpu,idlew 2>/dev/null | tail -1)"
CPU="$(echo "$LINE" | awk '{print $2}')"
WAKEUPS="$(echo "$LINE" | awk '{print $3}')"
WAKEUPS_PER_MIN="$(awk -v w="$WAKEUPS" -v s="$SECONDS_TO_SAMPLE" 'BEGIN { printf "%.1f", w * 60 / s }')"
FOOTPRINT_MB="$(footprint "$PID" 2>/dev/null | awk '/Footprint:/ { for (i = 1; i <= NF; i++) if ($i == "Footprint:") { v = $(i + 1); u = $(i + 2) } } END { if (u == "KB") v /= 1024; if (u == "GB") v *= 1024; printf "%.1f", v }')"
RSS_MB="$(ps -o rss= -p "$PID" | awk '{ printf "%.0f", $1 / 1024 }')"

printf "%-22s %8s %10s\n" "metric" "value" "budget"
printf "%-22s %8s %10s\n" "cpu %" "$CPU" "< $MAX_CPU"
printf "%-22s %8s %10s\n" "footprint MB" "$FOOTPRINT_MB" "< $MAX_FOOTPRINT_MB"
printf "%-22s %8s %10s\n" "idle wakeups / min" "$WAKEUPS_PER_MIN" "< $MAX_WAKEUPS_PER_MIN"
printf "%-22s %8s %10s\n" "rss MB (shared incl.)" "$RSS_MB" "-"

FAIL=0
awk -v a="$CPU" -v b="$MAX_CPU" 'BEGIN { exit !(a >= b) }' && { echo "FAIL: CPU over budget"; FAIL=1; }
awk -v a="$FOOTPRINT_MB" -v b="$MAX_FOOTPRINT_MB" 'BEGIN { exit !(a >= b) }' && { echo "FAIL: memory over budget"; FAIL=1; }
awk -v a="$WAKEUPS_PER_MIN" -v b="$MAX_WAKEUPS_PER_MIN" 'BEGIN { exit !(a >= b) }' && { echo "FAIL: too many wakeups"; FAIL=1; }

[[ $FAIL -eq 0 ]] && echo "PASS: within budget"
exit $FAIL
