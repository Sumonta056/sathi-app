# Phase 5g: review fixes

Source: code review of slice 5g (2026-10-25). Base spec: `docs/specs/phase-5g-reports.md`.

User choices (2026-10-25): a cancel keeps the old note; the save panel is a sheet on the Reports window; the PDF names the habit of the facts.

## G1 (MAJOR): cache the report screen

`ReportsView.body` calls `e.reportScreen` on every `Engine` publish. In a session that is every second, and each call reads month files from disk.

- `Engine` keeps one cached `ReportScreen` with its key: `range`, `selected`, `calendar.startOfDay(clock.now)`.
- `reportScreen(_:selected:)` returns the cached value when the key is the same. Else it builds, stores, and returns.
- The cache is cleared everywhere `clearStreakCache()` runs (events, streak reset, or goals changed) and also when the enabled habits change.
- `DateFormatter`s in `ReportScreenBuilder` are made once per builder, not once per call of a helper.

Tests:
1. Two calls with the same key read history once (`InMemoryHistoryStore` counts `events(from:to:)` calls).
2. A new done event, a goal change, an enabled change, a new day, a new range, and a new selected habit each rebuild.

## G2 (MAJOR): no silent defaults on the builder

Replace the 8 parameters with one input:

```swift
package struct ReportScreenInput: Sendable {
    package var range: ReportRange
    package var selected: HabitID
    package var report: Report
    package var month: Report
    package var enabled: Set<HabitID>
    package var streak: Int
    package var longest: Int
    package var now: Date
    package init(range:selected:report:month:enabled:streak:longest:now:)
}
package func build(_ input: ReportScreenInput) -> ReportScreen
```

No default values. Remove the old `build(range:…)`. Update the fixture and the callers.

## G3 (MINOR): day labels from the planned hour

Day bar label of index `i` = the hour `i * Limits.reportDayBucketHours` as "12a", "2a" … "10p". Never from the bucket start date.

Test: America/New_York 2026-03-08 and America/Santiago 2026-09-06 give the same 12 labels as a normal day.

## G4 (MINOR): export note rules

Pure function in UI: `ExportNote.next(_ old: ExportNote?, _ outcome: ExportOutcome) -> ExportNote?`.

| Outcome | Result |
|---|---|
| `.cancelled` | `old` (unchanged) |
| `.saved(url)` | `.saved(url.lastPathComponent)` |
| `.failed` | `.failed` |

`ReportsView` never clears the note before an export. It sets `note = ExportNote.next(note, outcome)` after the await.

Tests: old saved + cancel → old saved; old failed + saved → saved; nil + cancel → nil; old saved + failed → failed.

## G5 (MINOR): save panel as a sheet

`SavePanelExporter` takes the Reports window (`weak var window: NSWindow?`, set by `ReportsWindow.make`) and uses `beginSheetModal(for:)`. With no window, it falls back to `runModal()`. The continuation resumes exactly once. No test (AppKit panel); the reviewer checks it.

## G6 (MINOR): `exportedAt` after the panel

`Engine.export` reads `clock.now.wholeSecond` again after `destination` returns, for `ExportJob.exportedAt`. The file name keeps the time before the panel.

Test: a spy exporter that advances the `FakeClock` by 5 minutes inside `destination`; the backup `exportedAt` is the later time and the file name keeps the first date.

## G7 (MINOR): prove off the main thread

Test: a history store spy records `Thread.isMainThread` in `allEvents()`. After `await engine.export(.csv, …)` the value is `false`. Same for `.json`.

## G8 (NIT): PDF names the habit

`ReportPDFPage` shows `screen.chart.title` (for example "Water · this week") as a heading above the facts.

Test: the PDF page view contains the chart title text.

## G9 (NIT): small cleanups

- Rename `SettingsWindowDelegate` to `WindowCloseWatcher`.
- `ExportJob.write(_ data:to:)` becomes `internal` if only Core uses it.
- `ReportChartView`: `BarMark(width: .ratio(UIMetrics.chartBarFill))`, drop the `GeometryReader`.

## Later (not in this round)

- PDF with 0 pages if `ImageRenderer.render` skips its closure.
- A stored selection of an off habit comes back when the habit is turned on again.
- 6-row months (March 2026) plus 3 facts in a 250-pt card: check in the 5h screenshot.
