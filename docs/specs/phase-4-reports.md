# Phase 4: Reports and export, core

Goal: pure Core logic for the Reports window (Phase 5): day, week, and month reports per habit, streaks across month files, and CSV and JSON export. No UI in this phase.

Rules: `.claude/rules/business-logic.md` ("Stats and reports"). Design: https://claude.ai/artifact/AgF243uMtC5H8ySBfdXx6e (Reports artboard).

## Report model (`SathiCore/Stats/`)

```swift
package enum ReportRange: String, CaseIterable, Sendable { case day, week, month }

package struct ReportBucket: Equatable, Sendable {
    package var start: Date
    package var end: Date
    package var total: Double
}

package struct HabitReport: Equatable, Sendable {
    package var habit: HabitID
    package var goal: Double
    package var buckets: [ReportBucket]
    package var total: Double
    package var averagePerDay: Double
    package var percentOfGoal: Int
    package var daysMet: Int
    package var bestDay: Date?
    package var snoozes: Int
}

package struct Report: Equatable, Sendable {
    package var range: ReportRange
    package var interval: DateInterval
    package var habits: [HabitReport]
}
```

## `ReportBuilder(calendar:)`

- `interval(_ range: ReportRange, containing now: Date) -> DateInterval`
  - day: start of `now`'s day to the start of the next day.
  - week: Monday 00:00 to the next Monday 00:00, whatever the user's locale (`firstWeekday` is ignored).
  - month: the first day of `now`'s month to the first day of the next month.
  - Built with calendar day arithmetic (DST-safe), not by adding seconds.
- `build(_ range: ReportRange, now: Date, events: [HistoryEvent], prefs: Prefs) -> Report`
  - `habits`: one `HabitReport` per `HabitID.allCases`, in that order. The UI filters off habits.
  - `goal` = that habit's `rules.dailyGoal` from the current `prefs`.
  - Buckets:
    - day: `Limits.reportDayBucketHours` (2) hour buckets → 12 buckets, 00:00–02:00 … 22:00–24:00.
    - week: 7 day buckets, Monday first.
    - month: one bucket per calendar day (28–31).
  - Bucket `total` = sum of `.done` amounts of that habit with `start <= date < end`.
  - `total` = sum of all bucket totals.
  - "Counted days" = days of the interval from its first day up to and including today. Future days never count. For `day` it is 1.
  - `averagePerDay` = `total / countedDays`.
  - `percentOfGoal` = `min(100, Int((averagePerDay / goal * 100).rounded()))`; 0 when `goal == 0`.
  - `daysMet` = counted days whose total ≥ `goal`, only when `goal > 0`.
  - `bestDay` = start of the counted day with the highest total (> 0); the earliest on a tie; `nil` when every total is 0.
  - `snoozes` = count of `.snooze` events of that habit inside the interval.
  - Events outside the interval are ignored.

## `StreakCalculator(calendar:)`

```swift
package func current(_ id: HabitID, goal: Double, reset: Date?, now: Date, load: (DateInterval) -> [HistoryEvent]) -> Int
package func longest(_ id: HabitID, goal: Double, reset: Date?, now: Date, load: (DateInterval) -> [HistoryEvent]) -> Int
```

- A day is met when `goal > 0` and the sum of that habit's `.done` amounts that day, counting only events after `reset`, is ≥ `goal`.
- `current`: today adds 1 when met. Today not met does not break the streak, because the day is not over. Then walk back from yesterday one day at a time while met. The walk stops at the first day that is not met or after `Limits.streakLookbackDays` (365). This is the same rule as the old `Stats.streak`.
- `load` is called once per calendar month that the walk needs, newest month first, and not again for a month already loaded. The walk never loads a month older than the day it stopped on.
- `longest`: the longest run of met days in the last `Limits.longestStreakLookbackDays` (365) days up to today.
- Days are calendar days (DST-safe).

## Engine

- `Engine.streak(_:)` uses `StreakCalculator.current` with `load = { history.events(from: $0.start, to: $0.end) }`. The streak is no longer capped by the 3-month window.
- The cache stays: computed once per day and cleared when `data` changes.
- `Stats.streak` is removed. `Stats.total` stays.
- New `Engine.report(_ range: ReportRange) -> Report`: loads `history.events(from:to:)` for the interval and calls `ReportBuilder.build` with `now` and the current prefs.
- New `Engine.longestStreak(_:) -> Int` with `StreakCalculator.longest`.

## History port

- `HistoryStore.allEvents() -> [HistoryEvent]`: every event in every month file, sorted by date. `FileHistoryStore` lists the `history` folder (files named `yyyy-MM.json` only), and includes pending in-memory events. Unreadable files are skipped (and stay blocked, as in Phase 2). The fakes return their events sorted.

## Export (`SathiCore/Export/`)

```swift
package enum ExportFormat: String, CaseIterable, Sendable { case csv, json }

package enum CSVExporter {
    package static func csv(_ events: [HistoryEvent], timeZone: TimeZone) -> String
}

package enum JSONExporter {
    package static func backup(prefs: Prefs, live: LiveState, events: [HistoryEvent], exportedAt: Date) -> Data
}

package protocol FileExporter: AnyObject {
    @discardableResult
    func save(_ data: Data, suggestedName: String, format: ExportFormat) -> Bool
}

package enum ExportNames {
    package static func fileName(_ format: ExportFormat, on date: Date, calendar: Calendar) -> String
}
```

- CSV:
  - Header line: `timestamp,habit,kind,amount`.
  - One line per event, sorted by date. Lines end with `\n`, including the last line.
  - `timestamp`: ISO 8601 with the UTC offset of `timeZone`, for example `2026-03-04T10:00:00+01:00`.
  - `habit` and `kind`: raw values. `amount`: shortest decimal, no trailing zeros (`1`, `0.25`, `15`).
- JSON backup: `{"schemaVersion": 1, "exportedAt": …, "prefs": …, "live": …, "events": […]}` with `JSONFiles` encoding (ISO 8601, sorted keys). It decodes back into the same prefs, live state, and events.
- File names: `Sathi-history-YYYY-MM-DD.csv` and `Sathi-backup-YYYY-MM-DD.json` (local date).
- `Engine.export(_ format: ExportFormat, to exporter: FileExporter) -> Bool`: builds the data from `history.allEvents()` (CSV) or prefs, live, and all events (JSON), with `exportedAt = clock.now`, and calls `exporter.save`. Returns its result. The PDF summary is Phase 5 (UI).

## Constants

- `Limits.reportDayBucketHours = 2`, `Limits.longestStreakLookbackDays = 365`.
- `StorageKeys.exportHistoryPrefix = "Sathi-history-"`, `exportBackupPrefix = "Sathi-backup-"`.

## Test support

- `SpyFileExporter`: records `(data, suggestedName, format)` and returns a settable result.
- `InMemoryHistoryStore` counts `events(from:to:)` calls with their intervals (to test month loading).

## Tests that define done

1. `ReportBuilder.interval`: day, week (a Sunday `now` belongs to the week that started the Monday before; with a calendar whose `firstWeekday` is 1 the result is the same), month (Feb in a leap year has 29 days), and a DST week in `America/New_York` still has 7 day buckets that each start at 00:00 local.
2. `build`: bucket counts 12 / 7 / days-in-month; bucket totals; only `.done` counts; another habit's events never count; events outside the interval are ignored; `averagePerDay` divides by counted days only (a Wednesday in a week → 3 days); `percentOfGoal` is capped at 100 and is 0 for goal 0; `daysMet`; `bestDay` with a tie; `snoozes`.
3. `StreakCalculator.current`: a streak that crosses two month boundaries (for example 70 days) is counted in full; `load` is called once per month, newest first, and never for a month older than the stop day; `reset` excludes events at or before it; goal 0 → 0; today not met and yesterday met → the run ending yesterday; today met → that run + 1; today and yesterday not met → 0.
4. `StreakCalculator.longest`: the longest run inside 365 days; a run older than 365 days is ignored.
5. Engine: `streak` after 70 met days in history is 70 (was capped before); `report(.week)` uses the history store; `longestStreak`.
6. CSV: header, sorting, timestamp with offset in a fixed time zone, amount formatting, trailing newline, empty input → header only.
7. JSON: decodes back to the same values; `schemaVersion` 1; `exportedAt` from the clock.
8. `ExportNames`: both names for a fixed date.
9. `Engine.export`: the spy gets the right name, format, and data; the return value passes through.
10. `FileHistoryStore.allEvents`: events of 3 month files, sorted; a non-history file in the folder is ignored; pending events are included.

## Decisions made while writing the tests

1. Tests check which month each `load` call covers and that it stays inside one calendar month, not its exact bounds.
2. A month file name must match `yyyy-MM.json` with a two-digit month. `2026-2.json` is ignored.
3. ReportBuilder, StreakCalculator, CSV, ExportNames, and JSON tests use fixed time zones. Engine and FileHistoryStore tests use `Calendar.current`.
4. `HistoryStore.allEvents()` is a protocol requirement.

## Review fixes (round 1)

### R1. Day boundaries are always the start of a calendar day (midnight-DST zones)
- Every day step in `ReportBuilder` and `StreakCalculator` uses `calendar.startOfDay(for:)` of the shifted date (or `calendar.dateInterval(of: .day, for:)`). Never keep a wall time from a previous day.
- In a zone where DST starts at midnight (Africa/Cairo, America/Santiago), the day after the change starts at its real start (01:00 that day, 00:00 on later days).

### R2. The current streak never exceeds the longest streak
- Both windows are `Limits.streakLookbackDays` (365) days including today. `current` counts at most 365 days. `longest` returns at least `current`.

### R3. Gregorian dates for storage, reports, and export
- `ReportBuilder`, `StreakCalculator`, `ExportNames`, `CSVExporter`, and `FileHistoryStore` use `Calendar(identifier: .gregorian)` with the time zone of the calendar they receive. A Buddhist or Japanese system calendar never changes a year, a month, or a file name.
- Month file names stay `yyyy-MM` in the Gregorian calendar.

### R4. Streak cost
- `Engine.streak` and `Engine.longestStreak` load months that are inside the in-memory window from `data.events`, not from the history store. Only older months go to `history.events(from:to:)`.
- Both values are cached per day. The cache is cleared only when `data.events`, `data.live.streakReset`, or a habit's `dailyGoal` changes, not on other pref changes (for example the name).

### R5. Smaller fixes
- `streak`, `longestStreak`, `report`, and `export` all use `clock.now`. The cache day is the start of `clock.now`'s day.
- `exportedAt` is `clock.now.wholeSecond`.
- `averagePerDay` divides the total of the counted days only. Events on future days of the interval never raise the average.

### Moved to Later
- `percentOfGoal` rounding (99.5 → 100) is a product choice.
- Export errors are silent (JSON encode failure, history folder listing error). Phase 5 adds error handling with the save panel.
- Export runs on the main thread. Phase 5 builds the data off the main actor.

### Tests that define done (round 1)
1. R1: in `Africa/Cairo` (DST starts Friday 2026-04-24 at 00:00 → 01:00): a streak of met days across that date counts every day; the week of 2026-04-20 has 7 buckets and each starts at that day's `startOfDay`; the day interval of 2026-04-23 ends at the start of 2026-04-24; an event on Saturday 2026-04-25 at 00:30 is in Saturday's bucket.
2. R2: 400 met days → `current == 365` and `longest == 365`. The existing lookback test changes from 366 to 365 (the requirement changed; say so).
3. R3: with a `Calendar(identifier: .buddhist)` in Berlin: `ExportNames` gives `Sathi-history-2026-03-04.csv`; the month report of 2026-03-04 runs from March 1 to April 1, 2026; `FileHistoryStore` writes `2026-10.json`; the CSV timestamp year is 2026.
4. R4: with a 20-day streak inside the window, `streak` makes no `events(from:to:)` call; with a 70-day streak, calls only for months older than the window; changing the name does not clear the cache (no new calls), logging water does; after logging the goal today, `streak` goes from 0 to 1.
5. R5: `exportedAt` is whole seconds with a fractional clock; a future-day event in the week does not change `averagePerDay`; just after midnight with no tick, `streak` and `report` agree on the day.
