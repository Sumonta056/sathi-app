---
name: perf-check
description: Measure Sathi's CPU, memory, and wakeups on the installed release build and compare with the budget. Use after changes to timers, animations, published state, or windows, when the user types /perf-check, or when the user says the app feels slow or the fan spins.
---

# /perf-check

Budget: idle CPU < 1%, footprint < 40 MB (< 50 MB after any window opened and closed), < 10 idle wakeups per minute. See `.claude/rules/performance.md`.

## Steps

1. Build and install the release app. Ask the user first, because this replaces `/Applications/Sathi.app`:
   ```
   ./build.sh --install
   ```
2. Wait 10 seconds, so that start-up work ends.
3. Idle check:
   ```
   ./scripts/perf.sh
   ```
   The 40 MB footprint budget applies only to a fresh launch with no window opened. If any window was opened since launch, use `MAX_FOOTPRINT_MB=50 ./scripts/perf.sh`.
4. Panel check. A script cannot open the menu bar panel. Ask the user to:
   1. Click the Sathi icon and keep the panel open.
   2. Run `SECONDS_TO_SAMPLE=10 MAX_CPU=10 ./scripts/perf.sh` (the animation may use a few % while open).
   3. Close the panel, wait 5 seconds, and run `./scripts/perf.sh` (with `MAX_FOOTPRINT_MB=50` if a window was opened since launch). CPU must return to under 1%.
5. Window check (after changes to windows, or when memory is in question). Ask the user to run it in Terminal and paste the table. Never run it yourself: it waits for Enter and exits 64 without a terminal.
   ```
   ./scripts/perf.sh --windows
   ```
   The user opens and closes Reports and Settings two times. Each reading must be < 50 MB, and cycle 2 must add < 3 MB to cycle 1. On a fresh launch, cycle 1 is about 23 MB over the baseline: that is the one-time cost of the first window, not a leak.
6. If a check fails, find the hotspot:
   ```
   sample $(pgrep -x Sathi) 3 | grep "(in Sathi)" | sed -E 's/^[ +!:|]*//' | sort | uniq -c | sort -rn | head -15
   ```
   Typical causes: a `TimelineView` with no `minimumInterval` or `paused:`, a repeating timer, an `@Published` value that changes every tick, or a date formatter inside `ForEach`.
7. Report a table: metric, value, budget, pass/fail. Compare with the numbers in `.claude/rules/performance.md`. If the new numbers are better, update that table.
