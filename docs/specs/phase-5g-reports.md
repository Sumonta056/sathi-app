# Phase 5g: Reports window

> Update 2026-10-25 (5h): the Export menu, `ExportNote`, `ReportPDFPage`, `PDFSummaryRenderer`, and `SavePanelExporter` were removed from the UI because the macOS save panel keeps 14–16 idle wakeups per minute. Core export (`Engine.export`, `ExportJob`, ports) stays.

Goal: build the canvas Reports artboard as its own 860×620 window. Day/Week/Month segment, one tile per habit, a bar chart with a dashed goal line, a month streak calendar, three facts, and an Export menu (CSV, PDF, JSON). Export asks for the file first, builds CSV and JSON off the main actor, and shows an error when it fails.

Rules: `.claude/rules/business-logic.md` (Stats and reports 1–11). Design: https://claude.ai/artifact/AgF243uMtC5H8ySBfdXx6e (Reports artboard, `project/Stats.dc.html`). Core report API: `docs/specs/phase-4-reports.md`.

Out of scope: deleting the old `Palette` (slice 5g2), the back arrow of the canvas (Reports is its own window with a close button).

User choices (2026-10-25): the calendar and the facts follow the selected tile. An off habit shows a dimmed tile with "Off" and cannot be selected. PDF is in 5g.

## Part 1: Core

### Constants

| Name | Value | File |
|---|---|---|
| `StorageKeys.exportSummaryPrefix` | `"Sathi-summary-"` | `StorageKeys.swift` |
| `Limits.headlineGreatPercent` | 100 | `Limits.swift` |
| `Limits.headlineGoodPercent` | 50 | `Limits.swift` |
| `Limits.monthLabelEvery` | 5 | `Limits.swift` |
| `Limits.streakLevelMid` | 0.5 | `Limits.swift` |

### `ExportFormat`

Add `case pdf`. `ExportNames.fileName(.pdf, …)` → `"Sathi-summary-YYYY-MM-DD.pdf"`.

### `ExportOutcome` (`Export/ExportOutcome.swift`)

```swift
package enum ExportOutcome: Equatable, Sendable {
    case saved(URL)
    case cancelled
    case failed
}
```

### `FileExporter` port (replaces the old one)

```swift
@MainActor
package protocol FileExporter: AnyObject {
    func destination(suggestedName: String, format: ExportFormat) async -> URL?
}
```

`nil` means the user cancelled. The port only picks a URL. Core writes the file.

### `SummaryRenderer` port (`Ports/SummaryRenderer.swift`)

```swift
@MainActor
package protocol SummaryRenderer: AnyObject {
    func pdf(for screen: ReportScreen) -> Data?
}
```

`nil` means the render failed.

### `HistoryStore`

The protocol becomes `HistoryStore: AnyObject, Sendable`. `FileHistoryStore` is already `@unchecked Sendable`. `InMemoryHistoryStore` (test support) becomes `@unchecked Sendable`.

### `ExportJob` (`Export/ExportJob.swift`)

A `Sendable` struct with `history: HistoryStore`, `prefs`, `live`, `exportedAt: Date`, `timeZone: TimeZone`. One `nonisolated` method:

```swift
package func write(_ format: ExportFormat, to url: URL) -> ExportOutcome
```

- `.csv`: `history.allEvents()` → `CSVExporter.csv` → UTF-8 data.
- `.json`: `history.allEvents()` → `JSONExporter.backup`.
- `.pdf`: returns `.failed` (PDF data never comes through a job).
- Writes with `Data.write(to:options: .atomic)`. A thrown error returns `.failed`. Success returns `.saved(url)`.

### `Engine.export` (replaces the old `export(_:to:) -> Bool`)

```swift
package func export(_ format: ExportFormat, screen: ReportScreen, to exporter: FileExporter, renderer: SummaryRenderer) async -> ExportOutcome
```

1. Name = `ExportNames.fileName(format, on: clock.now.wholeSecond, calendar: calendar)`.
2. `await exporter.destination(…)`. `nil` → return `.cancelled`. Nothing else is read.
3. `.pdf`: `renderer.pdf(for: screen)`. `nil` → `.failed`. Else write the data off the main actor (`Task.detached`) like a job, with the same outcomes.
4. `.csv` / `.json`: build an `ExportJob` on the main actor (`exportedAt = clock.now.wholeSecond`), then `await Task.detached { job.write(format, to: url) }.value`.

### `ReportScreen` model (`Stats/ReportScreen.swift`, values only)

```swift
package struct ReportScreen: Equatable, Sendable {
    package var range: ReportRange
    package var selected: HabitID
    package var headline: String
    package var subline: String
    package var tiles: [ReportTile]
    package var chart: ReportChart
    package var calendar: StreakMonth
    package var facts: [ReportFact]
}
package struct ReportTile: Equatable, Sendable, Identifiable {
    package var habit: HabitID
    package var id: HabitID { habit }
    package var label: String
    package var value: String
    package var unit: String
    package var percent: Int
    package var note: String
    package var isOff: Bool
}
package struct ReportChart: Equatable, Sendable {
    package var title: String
    package var bars: [ReportBar]
    package var goal: Double?
}
package struct ReportBar: Equatable, Sendable, Identifiable {
    package var id: Int
    package var label: String
    package var value: Double
    package var metGoal: Bool
}
package struct StreakMonth: Equatable, Sendable {
    package var title: String
    package var streakText: String
    package var leadingBlanks: Int
    package var cells: [StreakCell]
}
package struct StreakCell: Equatable, Sendable, Identifiable {
    package var day: Int
    package var id: Int { day }
    package var level: Int
    package var isToday: Bool
    package var isFuture: Bool
}
package struct ReportFact: Equatable, Sendable, Identifiable {
    package var label: String
    package var id: String { label }
    package var value: String
}
```

### `ReportScreenBuilder` (`Stats/ReportScreenBuilder.swift`, pure)

```swift
package struct ReportScreenBuilder: Sendable {
    package init(calendar: Calendar)
    package func build(range: ReportRange, selected: HabitID, report: Report, month: Report, enabled: Set<HabitID>, streak: Int, longest: Int, now: Date) -> ReportScreen
}
```

All dates use `Calendar.gregorian(in: calendar.timeZone)` and a `DateFormatter` with locale `en_US_POSIX` and the formats below. Split it into small files (`+Tiles`, `+Chart`, `+Calendar`, `+Text`) to stay under 200 lines.

**Selected habit.** If `selected` is off, use the first enabled habit in `HabitID.allCases` order. If no habit is enabled, use `.water`.

**Range word.** day "Today", week "This week", month "This month".

**Headline.** Average of `percentOfGoal` over the enabled habits (integer division).

| Average | Headline |
|---|---|
| ≥ 100 | "{Range word}, you did great" |
| ≥ 50 | "{Range word}, nice progress" |
| < 50 | "{Range word}, every bit counts" |
| no enabled habit | "{Range word}, your buddies are resting" |

**Subline** (from `report.interval`):

| Range | Format | Example |
|---|---|---|
| day | `EEEE, d MMMM` | "Saturday, 24 October" |
| week, same month | `d` – `d MMMM` | "19 – 25 October" |
| week, two months | `d MMMM` – `d MMMM` | "28 September – 4 October" |
| month | `MMMM yyyy` | "October 2026" |

The week end is the last day inside the interval (`interval.end` minus one day). The dash is " – " (U+2013 with spaces).

**Tiles.** One per `HabitID.allCases`, in order.

| Field | Value |
|---|---|
| `label` | `habit.name.uppercased()` |
| `value` | day: `total`; week, month: `averagePerDay`. Water: `String(format: "%.1f")`. Reading, meditation: `Int(x.rounded())` |
| `unit` | water "glasses", others "min"; then day " today", else " / day" |
| `percent` | `percentOfGoal` |
| `note` | "{percent}% of your daily goal"; off habit: "Off" |
| `isOff` | `!enabled.contains(habit)` |

**Chart** (selected habit).

| Field | Day | Week | Month |
|---|---|---|---|
| `title` | "{Name} · today" | "{Name} · this week" | "{Name} · this month" |
| bar labels | bucket start hour: "12a", "2a" … "10a", "12p", "2p" … "10p" | "Mon" … "Sun" | day number on day 1, 6, 11 … (every `monthLabelEvery`), else "" |
| `goal` | `nil` | `report.goal` (nil when goal is 0) | same as week |
| `metGoal` | `value > 0` | `goal > 0 && value >= goal` | same as week |

`id` is the bucket index. `value` is the bucket total.

**Streak calendar** (selected habit, from `month`).

- `title`: "{MMMM} streak" (month of `now`), for example "October streak".
- `streakText`: `streak` == 1 → "1 day", else "{n} days".
- `leadingBlanks`: weekday of day 1, Monday first (Monday = 0, Sunday = 6).
- One cell per day of the month. `ratio = total / goal` (goal 0 → 0).
- `level`: 0 when ratio is 0, 1 when ratio < `streakLevelMid`, 2 when ratio < 1, 3 when ratio ≥ 1.
- `isToday`: the day of `now`. `isFuture`: day start > `now`. A future day has level 0.

**Facts** (selected habit), in this order:

| Label | Value |
|---|---|
| "Best day" (week, month only) | week: `EEEE` of `bestDay`; month: `d MMMM`; no best day: "—" |
| "Snoozes today" / "Snoozes this week" / "Snoozes this month" | `snoozes` |
| "Longest streak" | `longest` == 1 → "1 day", else "{n} days" |

### `Engine` additions (`Engine+Reports.swift`, split if needed)

- `package func reportScreen(_ range: ReportRange, selected: HabitID) -> ReportScreen`: `report(range)`, `report(.month)`, enabled habits from prefs, `streak(selected')`, `longestStreak(selected')` where `selected'` is the fallback habit, `clock.now`.
- `package func openReports()` → `presenter.showReports()`.
- `ReminderPresenter` gets `func showReports()`. `SpyPresenter` records `.showReports`.

## Part 2: UI

All `internal` except what `UIController` needs. `Night` colors and `Typography` only. No timers, no animation loops.

### Constants (`UIMetrics+Reports.swift`)

`reportsSize` 860×620, `reportsPadding` 22/28, `reportsGap` 16, `tileGap` 12, `tileMeterHeight` 6, `chartBarMaxWidth` 34, `chartBarRadius` 7, `chartGoalDash` [4, 4], `calendarWidth` 250, `calendarCellGap` 5, `calendarCellRadius` 5, `exportMenuWidth` 210, `pdfPageSize` 595×842. Streak cell opacities for level 1/2/3: 0.25, 0.6, 1.

### Views (`Features/Reports/`)

| View | Content |
|---|---|
| `ReportsView(exporter:renderer:)` | `@State range = .week`, `@State selected = .water`, `@State note: ExportNote?`. Reads `e.reportScreen(range, selected:)` in `body`. Header, tiles, chart + calendar row. |
| `ReportsHeader` | `screen.headline` (`heroTitle`), `screen.subline` (`hint`), `RangeSegment`, `ExportMenu`. |
| `RangeSegment` | Buttons "Day", "Week", "Month". The selected one has `accessibilityAddTraits(.isSelected)`. |
| `HabitTileView(tile:)` | Dot, label, value + unit, meter (`percent`), note. Selected: habit color border. Off: `opacity` 0.5 and disabled. Tap → `selected = tile.habit`. |
| `ReportChartView(chart:habit:)` | Swift Charts `BarMark` per bar (`metGoal` → habit color, else color at 0.5), `RuleMark` dashed at `goal` when not nil. Legend "Daily goal" only when `goal != nil`. |
| `StreakCalendarView(month:)` | Title, `streakText` (sprout), weekday headers "M T W T F S S", blanks, cells. Today has a `Night.text` outline. |
| `ReportFactsView(facts:)` | One row per fact: label (`hint`), value (`text`, bold). |
| `ExportMenu(onPick:)` | SwiftUI `Menu` titled "Export" with 3 items: "CSV spreadsheet" (`.csv`), "PDF summary" (`.pdf`), "JSON backup" (`.json`). |
| `ExportNoteView(note:)` | `.saved(name)` → "Saved {file name}" (`muted`). `.failed` → "Could not save the file. Try again." (reading color). |
| `ReportPDFPage(screen:)` | A4 page, white background, black text: headline, subline, one row per tile (label, value, unit, note), and the facts. No chart. |

`ExportNote` is `.saved(String)` or `.failed`. A cancel clears nothing and shows nothing. A new export clears the old note first.

### Platform and windows

- `Platform/SavePanelExporter`: `FileExporter`. `NSSavePanel`, `nameFieldStringValue = suggestedName`, `allowedContentTypes` from the format (`.commaSeparatedText`, `.json`, `.pdf`). `.OK` → URL, else `nil`.
- `Platform/PDFSummaryRenderer`: `SummaryRenderer`. `ImageRenderer(content: ReportPDFPage(screen:))` → `render { size, draw in }` into a `CGContext(consumer:mediaBox:)` PDF context. Returns `nil` when the context cannot be made.
- `Windows/ReportsWindow.make(engine:closeWatcher:)`: like `SettingsWindow`. Title "Sathi Reports", `reportsSize`, dark, `Night.bg`. Root `ReportsView(exporter: SavePanelExporter(), renderer: PDFSummaryRenderer())`.
- `UIController.showReports()`: like `showSettings()`. On close, set `contentView = nil` and release the window (reuse `SettingsWindowDelegate` as a generic close watcher).

### Entry points

- `MenuFooter`: the "Reports" icon is enabled: `MenuBarWindow.close()`, then `e.openReports()`.
- `OpenReportsRow`: enabled, no "Soon" badge, color `Night.text`, action `e.openReports()`.

## Tests that define done

### Core

1. `ExportNames.fileName(.pdf, …)` is "Sathi-summary-2026-03-04.pdf".
2. `Engine.export(.csv)`: a cancelled destination returns `.cancelled`, writes nothing, and never calls `history.allEvents()`.
3. `Engine.export(.csv)` to a temp URL writes the CSV (header plus one row per event) and returns `.saved(url)`; the exporter got "Sathi-history-2026-03-04.csv".
4. `Engine.export(.json)` writes a backup that decodes; `exportedAt` is the whole-second clock time.
5. `Engine.export(.pdf)` writes the renderer's data and returns `.saved`. A `nil` render returns `.failed` and writes no file.
6. A write into a folder that does not exist returns `.failed`.
7. `ExportJob.write(.pdf, …)` returns `.failed`.
8. Headline: each of the 4 rows of the headline table, for the day, week, and month range words.
9. Subline: day, week in one month, week across two months, month.
10. Tiles: order, labels, water value "7.5" with one decimal, reading value rounded, units for day and week, note text, `isOff` and "Off" note for a disabled habit.
11. Selected fallback: off selected → first enabled; nothing enabled → water.
12. Chart: titles for each range; day labels "12a", "2a", "12p", "10p" at the right indexes; week labels Mon…Sun; month labels only on days 1, 6, 11 …; `goal` nil for day and for goal 0; `metGoal` at the goal edge (equal counts as met).
13. Calendar: title "October streak"; "1 day" / "12 days"; `leadingBlanks` for a month that starts on Monday (0) and Sunday (6); cell count = days in month; levels 0/1/2/3 at the edges (0, just under 0.5, 0.5, just under 1, 1); `isToday`; a future day is `isFuture` with level 0.
14. Facts: no "Best day" for day range; best day weekday for week; "d MMMM" for month; "—" when no best day; snooze labels per range; "1 day" / "19 days".
15. `Engine.reportScreen` uses the fallback habit for streak and longest streak.
16. `Engine.openReports()` calls `presenter.showReports()`.
17. The old `Bool` export tests are rewritten to the new API (no test is deleted without a replacement).

### UI (ViewInspector)

18. `ReportsView` shows the headline and subline of `e.reportScreen(.week, selected: .water)`.
19. `RangeSegment` has "Day", "Week", "Month"; a tap on "Day" changes the headline to start with "Today".
20. 3 tiles; a tap on the reading tile changes the chart title to "Reading · this week".
21. An off habit tile shows "Off" and is disabled.
22. `ExportMenu` has the 3 item titles.
23. Export with a spy exporter that returns `nil` shows no note; a spy exporter with a temp URL shows "Saved Sathi-history-…csv"; a failing path shows "Could not save the file. Try again."
24. `StreakCalendarView` shows the title, the streak text, 7 weekday headers.
25. `ReportFactsView` shows each label and value.
26. `OpenReportsRow` is enabled, has no "Soon", and a tap calls `showReports` on the spy presenter.
27. `MenuFooter` "Reports" button is enabled.
28. `PDFSummaryRenderer().pdf(for:)` returns data that starts with "%PDF".
