---
paths:
  - "Sources/**/*.swift"
---

# Performance rules

Budget (checked by `./scripts/perf.sh` on the installed release build):

| Metric | Budget | Measured on 2026-10-24 |
|---|---|---|
| Idle CPU | < 1% | 0.0% |
| Memory footprint | < 40 MB | 19 MB |
| Idle wakeups | < 10 / min | 0 / min |

Before the refactor the app used 27–36% CPU and 66 MB. Do not let it go back.

## Timers

- The Engine has no repeating timer. `TickPlanner.delay` picks the next wake-up: the nearest deadline, the next minute change of the menu label, or 60 s at most. It uses 1 s only during a reading session.
- Every action that changes a deadline calls `requestTick()`. Do not add `Timer.scheduledTimer(... repeats: true)` to Core.
- Give every timer a tolerance (`TickPlanner.tolerance`).

## SwiftUI

- `TimelineView(.animation)` must have `minimumInterval: UIMetrics.animationFrameInterval` and a `paused:` condition when the view can be hidden. `BuddyView` pauses on `onDisappear`.
- Do not publish values that change every second from `Engine` unless a visible view needs them. The menu bar label observes only `StatusModel`, which publishes on real change.
- Precompute static lists (see `TimeSlots.all`). Do not format dates inside `ForEach` on each render.
- Cache expensive derived values and clear the cache on data change (see `Engine.streak` and `StatusIcon.image`).

## Memory

- Close windows with `orderOut` and drop the reference, so that the hosting view is freed.
- Keep history pruned (`Limits.historyRetentionDays`).

## How to check

1. `./build.sh --install`
2. Wait 10 s, then `./scripts/perf.sh`.
3. Open the menu panel, wait, close it. Run `./scripts/perf.sh` again. CPU must go back to ~0%.
4. To find a hotspot: `sample $(pgrep -x Sathi) 3 | grep "(in Sathi)" | sort | uniq -c | sort -rn | head`.
