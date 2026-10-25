---
paths:
  - "Sources/**/*.swift"
---

# Performance rules

Budget (checked by `./scripts/perf.sh` on the installed release build; the after-window row by `./scripts/perf.sh --windows`):

| Metric | Budget | Measured on 2026-10-25 |
|---|---|---|
| Idle CPU | < 1% | 0.0% |
| Memory footprint, fresh idle | < 40 MB | 17 MB |
| Memory footprint, after any window opened and closed | < 50 MB | 40–42 MB |
| Idle wakeups | < 10 / min | 0–6 / min |
| CPU with the Reports window open | < 10% | 0.3% |

The first SwiftUI window (Settings or Reports) loads the window frameworks, fonts, and symbols once, about 23 MB. A process cannot unload them, so memory stays there after the close. A second window adds only 1–2 MB. Swift Charts is not the cost (Settings alone costs the same). Only a separate helper process could give it back; not worth it for now.

`NSSavePanel` keeps XPC connections to the macOS save service after use: 14–16 idle wakeups per minute until quit. That is why the Reports window has no Export menu for now.

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
- The Engine keeps only `Limits.monthsInMemory` months of events in RAM. Older months load on demand and are not cached.

## How to check

1. `./build.sh --install`
2. Wait 10 s, then `./scripts/perf.sh`.
3. Open the menu panel, wait, close it. Run `./scripts/perf.sh` again. CPU must go back to ~0%.
4. After a window change: `./scripts/perf.sh --windows`. It asks you two times to open and close Reports and Settings. Each reading must be < 50 MB, and cycle 2 must add < 3 MB to cycle 1.
5. To find a hotspot: `sample $(pgrep -x Sathi) 3 | grep "(in Sathi)" | sort | uniq -c | sort -rn | head`.
