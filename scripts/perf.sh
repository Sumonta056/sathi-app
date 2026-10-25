#!/bin/bash
set -euo pipefail

MAX_CPU="${MAX_CPU:-1.0}"
MAX_FOOTPRINT_MB="${MAX_FOOTPRINT_MB:-40}"
MAX_WAKEUPS_PER_MIN="${MAX_WAKEUPS_PER_MIN:-10}"
SECONDS_TO_SAMPLE="${SECONDS_TO_SAMPLE:-30}"
MAX_WINDOW_FOOTPRINT_MB="${MAX_WINDOW_FOOTPRINT_MB:-50}"
MAX_LEAK_MB="${MAX_LEAK_MB:-3}"
SETTLE_SECONDS="${SETTLE_SECONDS:-5}"

USAGE="Usage: $0 [--windows]"

MODE="idle"
if [[ $# -gt 1 ]]; then
  echo "$USAGE" >&2
  exit 64
fi
if [[ $# -eq 1 ]]; then
  case "$1" in
    --windows) MODE="windows" ;;
    *) echo "$USAGE" >&2; exit 64 ;;
  esac
fi

PID="$(pgrep -x Sathi || true)"
if [[ -z "$PID" ]]; then
  echo "Sathi is not running. Start it with: open /Applications/Sathi.app"
  exit 2
fi

footprint_mb() {
  local raw value
  raw="$(footprint "$1" 2>/dev/null || true)"
  value="$(echo "$raw" | awk '/Footprint:/ { for (i = 1; i <= NF; i++) if ($i == "Footprint:") { v = $(i + 1); u = $(i + 2); found = 1 } } END { if (!found) exit 1; if (u == "KB") v /= 1024; if (u == "GB") v *= 1024; printf "%.1f", v }')" || {
    echo "could not read footprint for pid $1" >&2
    return 1
  }
  echo "$value"
}

at_least() {
  awk -v a="$1" -v b="$2" 'BEGIN { exit !(a >= b) }'
}

run_idle() {
  echo "Sampling Sathi (pid $PID) for ${SECONDS_TO_SAMPLE}s…"
  local line cpu wakeups wakeups_per_min footprint rss
  line="$(top -l 2 -s "$SECONDS_TO_SAMPLE" -pid "$PID" -stats pid,cpu,idlew 2>/dev/null | tail -1)"
  cpu="$(echo "$line" | awk '{print $2}')"
  wakeups="$(echo "$line" | awk '{print $3}')"
  wakeups_per_min="$(awk -v w="$wakeups" -v s="$SECONDS_TO_SAMPLE" 'BEGIN { printf "%.1f", w * 60 / s }')"
  footprint="$(footprint_mb "$PID")" || exit 1
  rss="$(ps -o rss= -p "$PID" | awk '{ printf "%.0f", $1 / 1024 }')"

  printf "%-22s %8s %10s\n" "metric" "value" "budget"
  printf "%-22s %8s %10s\n" "cpu %" "$cpu" "< $MAX_CPU"
  printf "%-22s %8s %10s\n" "footprint MB" "$footprint" "< $MAX_FOOTPRINT_MB"
  printf "%-22s %8s %10s\n" "idle wakeups / min" "$wakeups_per_min" "< $MAX_WAKEUPS_PER_MIN"
  printf "%-22s %8s %10s\n" "rss MB (shared incl.)" "$rss" "-"

  local fail=0
  at_least "$cpu" "$MAX_CPU" && { echo "FAIL: CPU over budget"; fail=1; }
  at_least "$footprint" "$MAX_FOOTPRINT_MB" && { echo "FAIL: memory over budget"; echo "If a window was opened since launch, the budget is 50 MB: MAX_FOOTPRINT_MB=50"; fail=1; }
  at_least "$wakeups_per_min" "$MAX_WAKEUPS_PER_MIN" && { echo "FAIL: too many wakeups"; fail=1; }

  [[ $fail -eq 0 ]] && echo "PASS: within budget"
  return $fail
}

measure_cycle() {
  echo "Cycle $1: open Reports and Settings, close both, then press Enter." >&2
  read -r || exit 64
  echo "Waiting ${SETTLE_SECONDS}s…" >&2
  sleep "$SETTLE_SECONDS"
  footprint_mb "$PID" || exit 1
}

run_windows() {
  [[ -t 0 ]] || { echo "--windows needs a terminal: run it yourself in Terminal" >&2; exit 64; }
  local baseline cycle1 cycle2 growth
  baseline="$(footprint_mb "$PID")" || exit 1
  echo "Baseline footprint: ${baseline} MB"
  cycle1="$(measure_cycle 1)" || exit $?
  cycle2="$(measure_cycle 2)" || exit $?
  growth="$(awk -v a="$cycle2" -v b="$cycle1" 'BEGIN { printf "%.1f", a - b }')"

  printf "%-22s %8s %10s\n" "reading" "MB" "budget"
  printf "%-22s %8s %10s\n" "baseline" "$baseline" "-"
  printf "%-22s %8s %10s\n" "cycle 1" "$cycle1" "< $MAX_WINDOW_FOOTPRINT_MB"
  printf "%-22s %8s %10s\n" "cycle 2" "$cycle2" "< $MAX_WINDOW_FOOTPRINT_MB"
  printf "%-22s %8s %10s\n" "growth (2 - 1)" "$growth" "< $MAX_LEAK_MB"

  local fail=0
  at_least "$cycle1" "$MAX_WINDOW_FOOTPRINT_MB" && { echo "FAIL: cycle 1 memory over budget"; fail=1; }
  at_least "$cycle2" "$MAX_WINDOW_FOOTPRINT_MB" && { echo "FAIL: cycle 2 memory over budget"; fail=1; }
  at_least "$growth" "$MAX_LEAK_MB" && { echo "FAIL: memory grows between cycles (leak)"; fail=1; }

  [[ $fail -eq 0 ]] && echo "PASS: within budget"
  return $fail
}

if [[ "$MODE" == "windows" ]]; then
  run_windows
else
  run_idle
fi
