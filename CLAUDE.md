# Sathi

Sathi is a macOS menu bar app (macOS 13+, Swift 5.9 tools, SwiftUI + AppKit). Two buddies remind the user: Fota (water) and Boi (reading). An ignored reminder escalates: bubble → persistent bubble → full-screen lock.

## Commands

| Task | Command |
|---|---|
| Build (debug) | `swift build` |
| Run all tests | `./scripts/test.sh` |
| Run one target or suite | `./scripts/test.sh SathiCoreTests` or `./scripts/test.sh "Engine flows"` |
| Lint and file-size check | `./scripts/lint.sh` (add `--fix` to auto-format) |
| Build, install, open | `./build.sh --install` |
| Performance budget | `./scripts/perf.sh` (needs the app running) |

## Module map

```
Sources/
  SathiCore/     Foundation only. All logic. Fully unit-tested.
    Models/        HabitID, Strictness, Container, Mood, Prefs, HistoryEntries, Persisted, ReminderState
    Constants/     Timing, Limits, StorageKeys, SoundName
    Scheduling/    Scheduler (due times), EscalationPolicy (bubble/lock), TickPlanner (timer delay)
    Stats/         Stats (daily totals, streak)
    Formatting/    Fmt, Copywriter
    Ports/         Clock, StateStore, SoundPlayer, ReminderPresenter (protocols + system impls)
    Engine/        Engine (+Loop, +Actions, +Display), StatusModel
  SathiUI/       SwiftUI + AppKit. Views and windows only.
    Constants/     UIMetrics, TimeSlots
    Theme/         Palette, ButtonStyles, ProgressBar, Shake, Color+Hex
    Buddy/         BuddyView, BuddyCanvas, BuddyPaths, GlassIcon, BottleView
    Features/      MenuBar/, Bubble/, Lock/, Session/, Celebrate/, Settings/
    Windows/       UIController (ReminderPresenter impl), LockScreen, PanelWindows
    Platform/      SystemSoundPlayer
  Sathi/         Executable. SathiApp, AppDelegate, AppEnvironment (composition root).
Tests/
  SathiTestSupport/  FakeClock, InMemoryStateStore, SpySoundPlayer, SpyPresenter, EngineHarness, day()
  SathiCoreTests/    Swift Testing unit tests for every Core module
  SathiUITests/      ViewInspector tests for views + engine interaction
```

Dependency direction: `Sathi → SathiUI → SathiCore`. Never the other way.

## Rules

Detailed rules live in `.claude/rules/`. They load when you touch matching files. The short version:

1. **No code comments** unless the user asks. SwiftLint enforces it (`no_comments`).
2. **One job per file. Max 200 lines per file.** `scripts/lint.sh` fails above 200. Split before you reach it.
3. **No magic numbers for behavior.** Durations go in `Constants/Timing.swift` or `UIMetrics.swift`. Ranges and thresholds go in `Constants/Limits.swift`. Storage keys go in `StorageKeys.swift`.
4. **SathiCore never imports AppKit or SwiftUI.** It talks to the outside through `Ports/`.
5. **Engine reads time only from `clock.now`.** Never `Date()` in Engine, Scheduling, or Stats.
6. **Use `package` access** for anything another target needs. Keep the rest `internal` or `private`.
7. **Performance budget:** idle CPU < 1%, memory footprint < 40 MB, < 10 idle wakeups per minute. No repeating 1-second timers. Animations cap at 30 fps and pause when hidden.
8. **Tests first** for every behavior change. Use `EngineHarness` and fakes. No real waits.

## Workflow

- Use the `/feature` skill for every change: plan → approval → failing tests → code → checks → review.
- Use the `/add-habit` skill to add a new habit (e.g. "stretch", "eyes").
- Use the `/perf-check` skill after any change to timers, animations, or published state.
- Ask before every `git commit` and `git push`. `main` is protected by a hook. Work on a branch.

## Definition of done

1. `./scripts/test.sh` passes.
2. `./scripts/lint.sh` passes.
3. `swift build -c release` passes with no new warnings.
4. For UI, timer, or animation changes: `./build.sh --install` then `./scripts/perf.sh` passes.
5. README and this file are updated if commands, modules, or rules changed.
