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
| `StateStore` | `UserDefaultsStateStore` | `InMemoryStateStore` |
| `SoundPlayer` | `SystemSoundPlayer` (SathiUI) | `SpySoundPlayer` |
| `ReminderPresenter` | `UIController` (SathiUI) | `SpyPresenter` |

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

- `Persisted` is `Codable`. Add new fields with a default value so old data still decodes.
- A breaking change needs a new key in `StorageKeys` and a migration in `UserDefaultsStateStore.load()`, with a test.
