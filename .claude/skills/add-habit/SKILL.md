---
name: add-habit
description: Add a new habit buddy to Sathi (for example stretch, eye break, walk). Use when the user types /add-habit <name> or asks for a new reminder type. Lists every file that must change, in order, with the tests for each step.
---

# /add-habit: add a new reminder habit

Input: `$ARGUMENTS` is the habit (name, buddy name, schedule rule, how it is "done").

Run the `/feature` loop. Use the steps below as the plan.

## 0. Make the compiler find every place (do this once)

Today `HabitID` has 2 cases, and most code uses ternaries like `id == .water ? a : b`. With a third case, these ternaries still compile and silently treat the new habit as reading.

Before you add the case:

1. Find them: `grep -rn -E "== \.water|== \.reading|\.water \?|\.reading \?" Sources`
2. Replace each one with an exhaustive `switch id { case .water: … case .reading: … }`.
3. Replace the `water` and `reading` stored properties in `Engine` with `@Published var habits: [HabitID: HabitState]`, and update `state(_:)` and `update(_:_:)`.
4. Run `./scripts/test.sh`. All tests must still pass. This step must not change behavior.

## 1. Model (SathiCore)

| File | Change |
|---|---|
| `Models/HabitID.swift` | New case. `name`, `buddy`. |
| `Models/Prefs.swift` | `<habit>Enabled`, schedule fields, `<habit>Strictness`. Give each a default so old saved data still decodes. Add schedule fields to `scheduleKey`. Extend `isEnabled` and `strictness`. |
| `Models/HistoryEntries.swift` + `Persisted.swift` | A new entry type and array only if the habit logs an amount. |
| `Constants/Limits.swift` | Ranges for the new settings. |

Tests: `ModelTests` (defaults, `scheduleKey`, old JSON without the new fields still decodes).

## 2. Rules (SathiCore)

| File | Change |
|---|---|
| `Scheduling/Scheduler.swift` | `next<Habit>Due(...)`. |
| `Stats/Stats.swift` | Daily total and goal for the streak. |
| `Formatting/Copywriter.swift` | Nudge and persist copy. Celebration titles. |

Tests: `SchedulerTests`, `StatsTests`, `CopywriterTests`.

## 3. Engine (SathiCore)

| File | Change |
|---|---|
| `Engine.swift` | Initial due time in `init`. |
| `Engine+Actions.swift` | The "done" action (like `logWater`). `lockConfirmed` and `emergencySkip` branches. |
| `Engine+Display.swift` | `mood`, `progress`, `subtitle`. |
| `Engine+Loop.swift` | Any time window rule in `enqueueDueHabits` (like water hours). |

Tests: `EngineFlowTests` (due → bubble → snooze → escalation → done), `EngineDisplayTests`.

## 4. UI (SathiUI)

| File | Change |
|---|---|
| `Theme/Palette.swift` | Accent and deep colors. `accent(_:)`, `deep(_:)`. |
| `Buddy/BuddyKind.swift`, `BuddyPaths.swift`, `BuddyCanvas.swift` | New buddy drawing in the 100 × 124 space. |
| `Features/Bubble/` | New section view (like `ReadingInfoCard`). Wire it in `BubbleView`. |
| `Features/MenuBar/HabitRow.swift` | Button title and action. |
| `Features/Lock/LockView.swift` | Headline and instructions. |
| `Features/Celebrate/` | Amount text and progress row. |
| `Features/Settings/` | New `<Habit>SettingsSection.swift`. Add it to `SettingsView`. |

Tests: one ViewInspector test per new view, plus a tap test that checks the Engine action.

## 5. Finish

1. `./scripts/lint.sh`, `./scripts/test.sh`, `swift build -c release`.
2. `/perf-check` (a new buddy adds an animation).
3. Update the README feature list.
