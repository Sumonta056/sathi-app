# Phase 5c: Menu bar popover

Goal: rebuild `MenuPanel` as the canvas popover: greeting and streak, one ring card per enabled habit, a sleeping row per disabled habit, pause chips, and an icon footer. The popover runs no animation loop.

Rules: `.claude/rules/business-logic.md` (Habits rule 4 and 6). Design: https://claude.ai/artifact/AgF243uMtC5H8ySBfdXx6e (Menu bar artboard). Shared parts: `docs/specs/phase-5a-theme.md`.

## Part 1: Core

### `Copywriter.greeting(at:name:calendar:) -> String`

| Hour of `at` (in `calendar`) | Text |
|---|---|
| `Limits.morningStartHour` (5) ..< `Limits.afternoonStartHour` (12) | "Good morning, {name}" |
| 12 ..< `Limits.eveningStartHour` (17) | "Good afternoon, {name}" |
| otherwise (17 ..< 24 and 0 ..< 5) | "Good evening, {name}" |

`{name}` is `Copywriter.displayName(name)` (existing). Add the three hours to `Limits`.

### `Engine.greeting: String`

`Copywriter.greeting(at: clock.now, name: data.prefs.general.name, calendar: calendar)`.

### `Engine.bestStreak: Int`

The highest `streak(id)` among the enabled habits. 0 when no habit is enabled.

### `Engine.pauseRestOfDay()`

Sets `pausedUntil` to the start of the next day after `clock.now` in `calendar` (DST-safe `date(byAdding: .day)` on `startOfDay`), then requests a tick, like `pause(hours:)`.

### `Engine.goalText(_ id: HabitID) -> GoalText`

```swift
package struct GoalText: Equatable, Sendable {
    package var done: String
    package var rest: String
}
```

| Habit | `done` | `rest` |
|---|---|---|
| Water | `Fmt.count(glassesToday)` | "of {goal} glasses" (goal = `Int(dailyGoalGlasses)`) |
| Reading | `min(readToday, sessionMinutes)` | "of {sessionMinutes} min" |
| Meditation | `min(doneMinutes, goal)` | "of {goal} min" (goal = `Int(rules(.meditation).dailyGoal)`) |

Exhaustive `switch` on `HabitID`.

## Part 2: UI (`Features/MenuBar/`)

All `internal` except `MenuPanel` (already `package`). `Night` colors and `Typography` only. The panel sets `.environment(\.colorScheme, .dark)` and fills `Night.bg`. `UIMetrics.menuWidth` becomes 380.

### `MenuPanel`

`VStack` of, in order:

1. `MenuHeader`: `e.greeting` (`Typography.heroTitle`), below it the date (`e.now`, weekday wide + day + month wide) and, when `e.bestStreak > 0`, " · {n}-day streak" (`hint`, `muted`). Static sprout logo on the right.
2. `NapBanner`, only when `e.pausedUntil != nil`: pause icon, text "Buddies are napping until {time}" (`time` = `pausedUntil` formatted `.shortened` time), button "Wake up" → `e.resume()`. Colors: reading hero fill/border, reading accent text.
3. `HabitCard(id:)` for each enabled habit in `HabitID.allCases` order.
4. `SleepingRow(id:)` for each disabled habit: dashed border (`fieldBorder`), text "{id.name} is sleeping" (`muted`), button "Turn on" (sprout) that sets the habit's `enabled` to true.
5. `Spacer`, then `PauseChips`: hint "Take a break from reminders", three equal buttons "30 min" → `e.pause(hours: 0.5)`, "1 hour" → `e.pause(hours: 1)`, "Rest of day" → `e.pauseRestOfDay()`. Pause lengths go in `Timing` (`shortPauseHours = 0.5`, existing `defaultPauseHours = 1`).
6. `MenuFooter` (top divider): icon buttons with accessibility labels "Reports" (disabled until 5g), "Settings" (closes the popover with `MenuBarWindow.close()`, then `e.openSettings()`), text "Sathi {version}" from `Bundle.main` `CFBundleShortVersionString` (fallback "Sathi"), and "Quit Sathi" (`NSApp.terminate`).

Keep `.onAppear { e.tick() }`.

### `HabitCard(id:)`

- `ProgressRing(progress: e.progress(id), accent: Night.accent(id))`: 52 pt, line 4, track `Night.border`, accent arc from the top, round cap, progress clamped 0...1. Inside, the static buddy (`StaticBuddy` from 5b) at 30 pt.
- Name `id.name` (15 pt black → add `Typography.cardTitle`), then the pill `e.pill(id)` (11 pt heavy, accent text on `Night.heroFill(id)`, capsule).
- Below: `goalText.done` (bold, `text`) + " " + `goalText.rest` (`hint`, `muted`).
- Accent button: "+1 glass" → `e.logWater(1)`, "Read now" → `e.startReading()`, "Breathe" → `e.startMeditation()`; text `Night.onAccent`; it calls `MenuBarWindow.close()` first. Exhaustive switch.
- Card: `Night.card` fill, `Night.border` border, radius `cardRadius`.
- Accessibility: the ring has label "{id.name} progress" and value "{percent}%".

### Delete

The old `HabitRow` and `MenuItem` (replaced). `ProgressBar` and `MiniButton` stay if other screens still use them.

### Constants

`UIMetrics`: `menuWidth` 380, `menuPadding` 16, `menuSpacing` 10, `ringSize` 52, `ringLine` 4, `ringBuddySize` 30, `actionHeight` 34, `pauseChipHeight` 34. `Limits`: the three greeting hours. `Timing.shortPauseHours` 0.5.

## Tests that define done

Core (`Tests/SathiCoreTests/`, `FakeClock` / fixed dates):

1. `greeting` at 05:00 and 11:59 → "Good morning, Mridul"; 12:00 and 16:59 → afternoon; 17:00, 23:59, 00:00, 04:59 → evening.
2. `Engine.greeting` uses the name from prefs and `clock.now`.
3. `bestStreak` is the max over enabled habits; a disabled habit with a longer streak is ignored; 0 when all are off.
4. `pauseRestOfDay` at 2026-03-04 15:00 → `pausedUntil` = 2026-03-05 00:00; on the DST day 2026-03-29 (Berlin) → 2026-03-30 00:00 local; no reminder shows before it; after it, due habits show.
5. `goalText` for each habit: water "2" / "of 8 glasses" after two glasses; reading caps `done` at the session length; meditation "0" / "of {goal} min".

UI (`Tests/SathiUITests/MenuBarTests.swift`, rewritten; ViewInspector + `EngineHarness`):

6. The panel shows `e.greeting` text and "-day streak" only when `bestStreak > 0`.
7. One `HabitCard` per enabled habit; one `SleepingRow` per disabled habit with "{name} is sleeping".
8. "Turn on" on the sleeping meditation row sets `prefs.meditation.enabled` to true.
9. The water card shows the pill and "+1 glass" logs one glass; "Read now" starts a reading session; "Breathe" starts meditation.
10. The ring of the water card has accessibility value "25%" after 2 of 8 glasses.
11. "30 min" pauses for 30 minutes, "1 hour" for 1 hour, "Rest of day" until midnight (check `pausedUntil`).
12. With `pausedUntil` set, the panel shows "Buddies are napping until" and "Wake up" resumes; without a pause, no banner.
13. "Settings" opens settings (`presenter.calls.last == .showSettings`); "Reports" is disabled; "Quit Sathi" exists.
14. `ProgressRing` clamps: progress 1.4 shows "100%", −0.2 shows "0%".

All old tests keep passing (rewrite only the menu bar tests that check removed views). No file over 200 lines. No comments.
