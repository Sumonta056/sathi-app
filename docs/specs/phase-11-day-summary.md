# Phase 11: Day summary

Every evening at a set time (default 22:00), a calm corner popup shows today's progress of the 4 buddies and congratulates the user when the goals are met.

## Rules

1. `GeneralPrefs.daySummaryOn` (default `true`) and `GeneralPrefs.daySummaryMinutes` (minutes after midnight, default `Limits.daySummaryMinutes` = 22 * 60). The time is picked in 15-minute steps (`Limits.scheduleSlotMinutes`). A saved value outside `0 ..< Limits.minutesPerDay` loads as the default.
2. The summary is due when it is on, `now` is at or after today's summary time, and it did not show today. It shows at most 1 time a day.
3. `LiveState.lastDaySummary: DayKey?` is set to today when the summary shows. An old `state.json` without the key loads `nil`. A key that cannot be read loads `nil`; the other live state stays.
4. A missed time (Mac asleep, app closed) shows the summary at the next tick of the same day, before midnight. After midnight it never shows for the day before.
5. A pause does not stop the summary. It is a report, not a reminder. It has no snooze, no ignore timer, no sound, no streak effect, and no history event.
6. A settings change that moves the time to or before `now` (on a day it did not show), or turns the switch on after the time, shows it at the next tick.
7. The popup uses the corner panel (`CornerToast`), never takes focus, and stays until the user closes it. Its one button "Good night" closes it. A second summary never opens while one shows.
8. The popup always has 4 rows, in `HabitID.allCases` order. Each row has one status:
   - `.off`: the habit is off. Dimmed row, text "Off".
   - `.dayOff`: the habit is on, today is a day off, and the goal is not met. Text "Day off".
   - `.progress(done, goal)`: every other case. Text from the habit's goal text, for example "6 of 8 glasses". A check mark when met.
   - Met means `goal > 0 && done >= goal` (Schedules rule 7).
   - Each row also shows the habit's current streak when it is more than 0.
9. The values are live for the day the popup opened for (`lastDaySummary`): a glass logged while it shows updates its row. After midnight, an open popup still shows that day, never the new day. Each row's text, bar, and check mark come from the same `.progress(done, goal)` value.
11. The popup has a fixed height while it shows: the title stays on 1 line (it shrinks to fit a long name) and every progress row keeps room for its streak line. The buddies in the popup are still drawings (no animation), because the popup can stay open all night.
12. Turning the switch off closes an open popup. A saved time that is not a multiple of `Limits.scheduleSlotMinutes` loads as the default.
10. Verdict, from the `.progress` rows only:
    - `allMet`: at least 1 row and every row is met. Header "Congratulations, {name}!" and "Every goal met today."
    - `someMet(met, of)`: at least 1 met, not all. Header "Good day, {name}." and "{met} of {of} goals met."
    - `noneMet`: at least 1 row, none met. Header "Rest well, {name}." and "Tomorrow is a new day."
    - `restDay`: no `.progress` rows. Header "Enjoy your rest, {name}." and "No goals today."

## Data shape

```swift
package struct DaySummary: Equatable, Sendable {
    package var rows: [DaySummaryRow]
    package var verdict: DaySummaryVerdict { ... }
}
package struct DaySummaryRow: Equatable, Sendable {
    package var id: HabitID
    package var status: DaySummaryStatus
    package var streak: Int
}
package enum DaySummaryStatus: Equatable, Sendable {
    case off
    case dayOff
    case progress(done: Double, goal: Double)
    package var isMet: Bool
}
package enum DaySummaryVerdict: Equatable, Sendable {
    case allMet, someMet(met: Int, of: Int), noneMet, restDay
}
```

## Engine API

- `package var daySummary: DaySummary` builds the rows from `enabled`, `isOffToday`, `rules(id).total(on: now, data:)`, `rules(id).dailyGoal`, and `streak`.
- `package func closeDaySummary()` calls `presenter.closeDaySummary()`.
- In `tick()`: when the summary is due, set `lastDaySummary` and call `presenter.showDaySummary()`.
- `upcomingDeadlines()` adds the next summary time (today's when not shown and in the future, else tomorrow's) when it is on. No new timer.

## Ports

`ReminderPresenter` gets `showDaySummary()` and `closeDaySummary()`.

## Files

- Core: `Stats/DaySummary.swift`, `Engine/Engine+DaySummary.swift`, `Formatting/Copywriter+DaySummary.swift`, `Models/GeneralPrefs.swift`, `Models/LiveState.swift`, `Constants/Limits.swift`, `Ports/ReminderPresenter.swift`, `Engine/Engine+Loop.swift`.
- UI: `Features/DaySummary/DaySummaryCard.swift`, `Features/DaySummary/DaySummaryRow.swift`, `Windows/UIController+Corner.swift` (or a new `UIController+DaySummary.swift`), `Features/Settings/GeneralTab.swift` (switch + time menu).
- Tests: `SathiCoreTests` for the verdict, the engine timing, and decoding; `SathiUITests` for the card.
