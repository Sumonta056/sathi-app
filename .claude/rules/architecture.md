---
paths:
  - "Sources/**/*.swift"
  - "Package.swift"
---

# Architecture rules

## Layers

- `SathiCore` holds every rule of the app: models, schedule, escalation, stats, formatting, and the `Engine` state machine. It imports only `Foundation` and `Combine`.
- `SathiUI` holds views, window management, and platform adapters. It reads state from `Engine` and calls `Engine` actions. It holds no business rules.
- `Sathi` (executable) only composes objects in `AppEnvironment` and starts the app.

Dependency direction: `Sathi → SathiUI → SathiCore`. A lint rule (`no_appkit_in_core`) blocks AppKit and SwiftUI imports in Core.

## Ports

The Engine talks to the outside world only through protocols in `Sources/SathiCore/Ports/`:

| Port | Production impl | Test impl |
|---|---|---|
| `Clock` | `SystemClock` | `FakeClock` |
| `StateStore` | `FileStateStore` (`prefs.json`, `state.json`) | `InMemoryStateStore` |
| `HistoryStore` | `FileHistoryStore` (`history/YYYY-MM.json`) | `InMemoryHistoryStore` |
| `SoundPlayer` | `SystemSoundPlayer` (SathiUI) | `SpySoundPlayer` |
| `ReminderPresenter` | `UIController` (SathiUI) | `SpyPresenter` |
| `FileExporter` | none yet (the Export menu was removed in 5h; see `docs/ROADMAP.md` Later) | `SpyFileExporter` |
| `SummaryRenderer` | none yet (the PDF renderer was removed in 5h) | `SpySummaryRenderer` |

To add a new side effect (notifications, analytics, file export), add a port protocol in Core, a real impl in UI or Platform, and a fake in `Tests/SathiTestSupport`.

## Where new code goes

| You are adding | Put it in |
|---|---|
| A pure rule or calculation | A struct or enum in `SathiCore/Scheduling`, `Stats`, or a new Core folder |
| A new reminder action | `Engine+Actions.swift` (split the file if it passes 200 lines) |
| Text or numbers the menu shows | `Engine+Display.swift` |
| A new screen | `SathiUI/Features/<Feature>/`, one view per file |
| A new window type | `SathiUI/Windows/` and a method on `ReminderPresenter` |
| A constant | `SathiCore/Constants/` (behavior) or `SathiUI/Constants/UIMetrics.swift` (layout, animation) |

## File size

- Max 200 lines per file. Max 150 lines per type body.
- When a view grows, extract a child view into its own file in the same feature folder.
- When an Engine extension grows, split it by topic (`Engine+Water.swift`, `Engine+Reading.swift`).

## Persistence

- Files live in `~/Library/Application Support/Sathi/`. `AppEnvironment` builds the base URL and both stores, and runs `LegacyMigrator` before the Engine. `AppDelegate.applicationWillTerminate` flushes both stores.
- Code lives in `SathiCore/Storage/`: `JSONFiles` (encoder, `Versioned<T>` wrapper, atomic write, corrupt-file rename), `FileStateStore`, `FileHistoryStore`, `LegacyMigrator`, and `Legacy/` (old v1 shapes).
- Every file is `{"schemaVersion": N, "value": ...}` with ISO 8601 dates and sorted keys. A file that does not decode is atomically renamed over `<name>.corrupt` and defaults load.
- Saves are coalesced: a save marks the file dirty and writes after `Timing.saveCoalesce` on the store's private serial queue. `flush()` writes now. No repeating timers.
- `flush()` returns `Bool`. A failed write stays pending and is retried by the next write or flush. A file that exists but cannot be read (or whose quarantine failed) is never written again in that session; its saves stay in memory.
- `LegacyMigrator` runs only while `<base>/migrated-v1` is missing. It flushes history first, then state, and writes the marker last, only when both flushes succeed. It skips legacy events the history already holds, and never overwrites an existing `prefs.json` or `state.json`.
- Stored times have 1-second precision: `HistoryEvent` dates, `lastWaterDone`, and `streakReset` values pass through `Date.wholeSecond` when created or decoded.
- The Engine saves prefs and live state from `data.didSet` only when that part changed. Events go only through `Engine.record(_:)` → `HistoryStore.append`. The Engine keeps `Limits.monthsInMemory` months of events in RAM.
- Every prefs struct and `LiveState` decode missing keys and unknown enum values to defaults (`value`, `known`, `knownSet` in `DecodingDefaults.swift`). `HistoryEvent` is strict; `MonthEvents` keeps an event or field it cannot read and writes it back. Add new fields with a default value. Details: `.claude/rules/storage.md`.
- A breaking change bumps `Limits.schemaVersion` and adds a migration with a fixture test.
