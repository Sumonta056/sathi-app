Spec: docs/specs/phase-18-app-window.md

# Phase 18 plan: main window, quick panel, one activity prompt, stats ranges

Worktree: `/Users/cefalo_1/Documents/Projects/Sathi-app-window`, branch `feat/app-window`. Each task ends green (tests + lint pass) and is 1 commit on this branch. Never push. Rule numbers ("rule 27") are the spec rules unless the text says "phase 17" or names a section of `.claude/rules/business-logic.md`.

## Global Constraints

- No code comments (SwiftLint `no_comments`). Max 200 lines per file and 150 lines per type body (`./scripts/lint.sh`). Split before the limit.
- No magic numbers: durations in `Sources/SathiCore/Constants/Timing.swift`, ranges and counts in `Sources/SathiCore/Constants/Limits.swift`, UI sizes in `Sources/SathiUI/Constants/UIMetrics*.swift` (new topic files are fine, for example `UIMetrics+MainWindow.swift`), colors in `Sources/SathiUI/Theme/NightPalette.swift`. All user-facing text in `Sources/SathiCore/Formatting/Copywriter+*.swift`.
- `SathiCore` never imports AppKit or SwiftUI. Core reads time only from `clock.now`, never `Date()`. Use `package` access across targets; keep the rest `internal` or `private`. Dependency direction `Sathi → SathiUI → SathiCore`.
- Every `switch` on `HabitID`, `PromptKind`, `ReportRange`, `MainPage`, `SettingsPage`, or `PromptReason` is exhaustive. No `default:`.
- Tests first for every behavior change: write the failing test, see it fail, then code. Swift Testing (`@Suite`, `@Test`, `#expect`) and ViewInspector 0.10. Use `EngineHarness` and the fakes in `Tests/SathiTestSupport/` (`FakeClock`, `SpyPresenter`, `InMemoryActivityStore`, `SpyCalendarWriter`, `day()`, `FixedZone`). No real waits, no `Date()` in tests. Expected values come from the spec, not from running the code. Never weaken a test; a test that changes because a rule changed is changed in its own explained step and named in the commit message.
- Performance budget: idle CPU < 1%, memory < 40 MB fresh and < 50 MB after a window, < 10 idle wakeups a minute, no repeating 1-second timers, animations ≤ 30 fps (`UIMetrics.animationFrameInterval`) and paused when hidden. Windows close with `orderOut` + `contentView = nil` + dropped reference. No `NSSavePanel`.
- Never lose user data. This phase changes no saved data: `prefs.json`, `state.json`, `history/`, `activities/`, and `PromptKind` raw values stay. If a task finds it needs a saved field, stop and follow `.claude/rules/storage.md` and the `/data-migration` skill first, and ask the user.
- Buddy reminders (bubble, corner popup, lock), quick reminder popups, and the day summary popup do not change.
- Keep accessibility identifiers that tests or the controller use (`tracker.start`, `tracker.skip`, `tracker.close`, `tracker.calendar.check`, `menu.tracker.*`, …) when a view keeps its role; new views get `main.*`, `today.*`, `quick.*`, `prompt.*`, `reports.*`, `activities.*` identifiers.
- Commands: `./scripts/test.sh <Target or Suite type name>` for the task's tests, then `./scripts/test.sh` (all), `./scripts/lint.sh`, and `swift build`. Commit message format `feat(app-window): …` / `refactor(app-window): …`, ending with the line `Claude-Session: https://claude.ai/code/session_01MyFrXZqCdGpeMkUh7Dbdbg`.
- Definition of done (`CLAUDE.md`): `./scripts/test.sh`, `./scripts/lint.sh`, `swift build -c release` with no new warnings; for UI, timer, or window changes `./build.sh --install` then `./scripts/perf.sh`, and the user runs `./scripts/perf.sh --windows`; `README.md` and `CLAUDE.md` updated; website via `/sathi-website` for user-visible changes. The last task updates the `CLAUDE.md` module map and `README.md`.

### Task 1: Rules and words first

Goal: change the business rules before any behavior (project rule 9).

Files:
- Modify `.claude/rules/business-logic.md`:
  - New section `## Main window` after `## Stats and reports`: spec rules 1–9 (one window, sidebar pages, Settings sub-pages, old paths → pages, Dock icon only while open, launch by user vs login item, close vs quit) and 16–19 (quick panel), short form, with "Full rules are in `docs/specs/phase-18-app-window.md`."
  - `## Stats and reports`: rule 3 week → "Week: 7 days from the region's first weekday (`Calendar.firstWeekday`) on the Gregorian calendar" for Reports and Activities ranges; add the range control, ‹ ›, and compare rules (spec 27–29); rule 7 → export CSV to `~/Downloads` with Finder, no save panel (spec 35, 39); rule 8 "Reports window" → "Reports page".
  - `## Activity tracker`: rewrite rule 3 (1 activity prompt at the center of the mouse display, 5 reasons, takes the keyboard only when the user opened it; spec 41–45), rule 12 (the calendar row in the prompt), and add rule 13 "Prompt actions" pointing to the mapping table (spec 52), rule 14 notes and end-of-day at center, end of day waits for an open prompt (spec 53, 54). Remove "A and C never take the keyboard unless the user clicks in them" and the corner column words. Rule 3a stays.
  - `## Quick reminders` rule 16: the list moves to Settings → Quick reminders; the quick panel has the "Quick reminder" button.
- Modify `GLOSSARY.md` only if a word is missing: check Main window, Quick panel, Range, Activity prompt (they exist); add **Reason** ("Why the activity prompt shows: time to ask, shortcut, activity ends, back from Away, or a calendar event. It sets the prompt's color, tag, and buttons." _Avoid_: kind, type, mode).
- Modify `docs/specs/phase-17-activity-tracker.md`: add 1 line under the title: "Phase 18 replaces the prompt layouts (rules 12, 13, 15–19, 44 places, 47 chips) with the one activity prompt: `docs/specs/phase-18-app-window.md` rules 41–54."

Tests: none (docs only).

Acceptance: the rules file has no word "corner" for tracker prompts, no "Settings window"/"Reports window" outside history notes; every spec rule 1–55 has a home (rules file or a pointer to the spec).

Commands: `./scripts/lint.sh` (no Swift change, must stay green). Commit `docs(app-window): business rules and words for the main window phase`.

### Task 2: `StatsRange` and the compare words (Core)

Goal: the range math of spec rules 27–29, pure and fully tested.

Files:
- Create `Sources/SathiCore/Stats/StatsRange.swift`: `package struct StatsRange: Equatable, Sendable { kind: ReportRange; interval: DateInterval }` with `static func containing(_ date: Date, kind: ReportRange, calendar: Calendar) -> StatsRange` (Gregorian in `calendar.timeZone`, `firstWeekday` copied from `calendar`), `previous`, `next`, `holds(_ date:)`, `days: [DateInterval]`, `canGoForward(now:)`, `changed(to kind: ReportRange, now:)` (keeps the first day, or today when the old range holds now).
- Create `Sources/SathiCore/Stats/StatsRange+Compare.swift`: `func comparable(now: Date, calendar:) -> DateInterval` (the previous range, cut at the same whole days + clock time when `self` holds `now`, never past its end).
- Create `Sources/SathiCore/Stats/RangeChange.swift`: `package enum RangeChange: Equatable { case up(Double), down(Double), same, none }` with `init(current: Double, previous: Double, hasData: Bool)`.
- Create `Sources/SathiCore/Formatting/Copywriter+Ranges.swift`: `rangeTitle(_:now:calendar:)` ("Today, 11 Nov", "Yesterday, 10 Nov", "Mon, 3 Nov", "3 – 9 Nov", "27 Oct – 2 Nov", "November 2026"), `rangeChange(_:kind:format:)` ("+6 vs last week", "−1 vs last week", "same as last week", "vs yesterday", "vs last month"; the minus sign is U+2212), `rangeSegment(_:)` ("Day", "Week", "Month").
- Do not change `Limits.weekStartWeekday` or `ReportBuilder.interval(_:containing:)` (other users keep Monday).

Tests first:
- `Tests/SathiCoreTests/StatsRangeTests.swift`: day/week/month intervals for a fixed date; week with `firstWeekday` 1 (Sunday) and 2 (Monday) (`@Test(arguments:)`); `previous`/`next` across a month and a year; `canGoForward` false on the range that holds now and true on the one before; `changed(to:)` keeps the first day / jumps to today; a DST week (use `FixedZone` with a DST zone) has 7 `days` that each start at `startOfDay`.
- `Tests/SathiCoreTests/StatsRangeCompareTests.swift`: Tue 14:52 week vs Mon 00:00 – Tue 14:52 last week; past range compares whole; 31-day month vs 30-day month cut stops at the previous end; day range vs yesterday same clock time.
- `Tests/SathiCoreTests/CopywriterRangesTests.swift`: every title form and every change word above.

Acceptance: R1, R2, R3 unit checks pass.

Commands: `./scripts/test.sh StatsRangeTests`, `./scripts/test.sh StatsRangeCompareTests`, `./scripts/test.sh CopywriterRangesTests`, `./scripts/test.sh`, `./scripts/lint.sh`, `swift build`. Commit `feat(app-window): stats ranges with previous-range compare`.

### Task 3: Buddy totals for a range (Core + Engine)

Goal: spec rules 31, 32 and the data for rule 34.

Files:
- Create `Sources/SathiCore/Stats/BuddyRangeReport.swift`: `package struct BuddyRangeTotal: Equatable, Identifiable { habit; total: Double; change: RangeChange; daysMet: Int; daysCounted: Int; isOff: Bool }` and `package struct GoalDayBar: Equatable { day: Date; met: Int; of: Int; isFuture: Bool }`.
- Create `Sources/SathiCore/Stats/BuddyRangeBuilder.swift`: `build(range: StatsRange, now:, events:, previousEvents:, prefs:, calendar:) -> (totals: [BuddyRangeTotal], bars: [GoalDayBar])`. Reuse `Stats.total` and `HabitDays` like `ReportBuilder.habitReport` (Stats rules 2, 4, 5). Days counted: up to today only; a day off counts only when met.
- Modify `Sources/SathiCore/Stats/ReportBuilder.swift`: add `build(_ range: StatsRange, now:, events:, prefs:) -> Report` that uses `range.interval` in place of `interval(_:containing:)`, so the existing chart, calendar, and facts can show any range (spec rule 34). Keep the old `build(_:now:events:prefs:)` as a 1-line call to the new one. Split into `ReportBuilder+Range.swift` if the file passes 200 lines.
- Create `Sources/SathiCore/Engine/Engine+RangeReports.swift`: `package func buddyRange(_ range: StatsRange) -> (totals, bars)`, `package func report(_ range: StatsRange) -> Report`, `package func reportScreen(_ range: StatsRange, selected: HabitID) -> ReportScreen`. Events inside RAM months come from `data.events`; older months load from `history.events(from:to:)` for the build only and are not cached (History rule 3).

Tests first:
- `Tests/SathiCoreTests/BuddyRangeBuilderTests.swift`: week totals per buddy in the goal unit; change vs a cut previous week; days met with a day off (met and not met); off habit `isOff` with totals kept; goal-day bars `met`/`of` per day and `isFuture` after today; Day range gives 1 bar.
- `Tests/SathiCoreTests/EngineRangeReportTests.swift` (EngineHarness with `history` events 5 months back): a range older than `Limits.monthsInMemory` gets its events; `report(StatsRange)` for the current week equals the old `report(.week)`.

Acceptance: R4 passes; existing `ReportBuilder*Tests` and `EngineReportScreenTests` unchanged and green.

Commands: `./scripts/test.sh BuddyRangeBuilderTests`, `./scripts/test.sh EngineRangeReportTests`, `./scripts/test.sh SathiCoreTests`, `./scripts/lint.sh`, `swift build`. Commit `feat(app-window): buddy totals and goal-day bars for any range`.

### Task 4: Activity stats, text, and CSV export for a range (Core + Engine)

Goal: spec rules 33, 38, 39 and Reports export (35).

Files:
- Create `Sources/SathiCore/Stats/ActivityRangeStats.swift`: from `[ActivityDay]` of the range and of the compare interval: tiles (Real work, Average day, Best day, Away) each with `RangeChange`, day rows (reuse `ActivityMonthRow`), category totals with change (`ActivityCategoryTotal` + change), and the extra rows "Calendar events" (kind `event`) and "Away" for Reports rule 33.
- Create `Sources/SathiCore/Stats/ActivityRangeText.swift`: the phase 17 rule 36 text with the range title in place of the month (reuse `ActivityMonthText` parts; make `ActivityMonthText.make` call it so the month text does not change).
- Create `Sources/SathiCore/Export/ActivityRangeExporter.swift`: `csv(_ items: [Activity], timeZone:)` with the `ActivityMonthExporter.csv` columns (move the shared row code into it and let `ActivityMonthExporter.csv` call it), `fileName(_ range: StatsRange, calendar:)` → `sathi-activities-{startKey}-{endKey}.csv`.
- Create `Sources/SathiCore/Export/HistoryRangeExporter.swift`: `fileName(_ range:, calendar:)` → `sathi-history-{startKey}-{endKey}.csv` (CSV body from `CSVExporter.csv`).
- Create `Sources/SathiCore/Engine/Engine+RangeActivities.swift`: `package func activityDays(in range: StatsRange) -> [ActivityDay]` (across months, today with the running activity), `package func activityRange(_ range: StatsRange) -> ActivityRangeStats`, `package func exportActivities(_ range:, to folder: URL) -> URL?`, `package func exportHistory(_ range:, to folder: URL) -> URL?`. Use `Engine.freeURL(in:name:)` from `Engine+TrackerExport.swift`. Write off the main thread like the month export does now (check `ActivityReportsView.swift:64` and `Engine+TrackerExport.swift` for the current pattern and keep it).
- Add `StorageKeys`/`ExportNames` constants for the 2 file name prefixes (no literal names in code).

Tests first:
- `Tests/SathiCoreTests/Tracker/Reports/ActivityRangeStatsTests.swift`: week tiles and change; categories longest first with change; "Calendar events" and "Away" rows; real work + Away + Not logged = tracked span (phase 17 G40) still holds per day.
- `Tests/SathiCoreTests/Tracker/Reports/ActivityRangeTextTests.swift`: week text; month text equals the old `ActivityMonthText` output for the same month (guard).
- `Tests/SathiCoreTests/Tracker/Reports/ActivityRangeExporterTests.swift` and `Tests/SathiCoreTests/HistoryRangeExportTests.swift`: columns, names, a range across 2 months.
- `Tests/SathiCoreTests/Tracker/Engine/EngineRangeExportTests.swift`: export into a temp folder (`TestFiles`), a second export gets a free name, nothing written for an empty range returns `nil`.

Acceptance: R5, A1 (data part), R6 (engine part) pass; existing `ActivityMonth*` tests unchanged and green.

Commands: `./scripts/test.sh ActivityRangeStatsTests`, `./scripts/test.sh ActivityRangeTextTests`, `./scripts/test.sh ActivityRangeExporterTests`, `./scripts/test.sh EngineRangeExportTests`, `./scripts/test.sh SathiCoreTests`, `./scripts/lint.sh`, `swift build`. Commit `feat(app-window): activity stats, text, and CSV export for any range`.

### Task 5: `MainPage` and one presenter call for the main window

Goal: spec rules 4, 5 at the port level, while the old windows still exist.

Files:
- Create `Sources/SathiCore/Models/MainPage.swift`: `package enum MainPage: Equatable, Sendable { case today, activities(DayKey?), reports, settings(SettingsPage) }` and `package enum SettingsPage: Hashable, Sendable { case general, habit(HabitID), quickReminders, tracker, timeBlocks, sound }` with `static var all: [SettingsPage]` in sidebar order (spec rule 3: General, the 4 buddies, Quick reminders, Activity tracker, Time blocks, Sound).
- Modify `Sources/SathiCore/Ports/ReminderPresenter.swift`: replace `showSettings()` and `showReports()` with `showMain(_ page: MainPage)`.
- Modify `Sources/SathiCore/Engine/Engine+Actions.swift`: `openSettings()` → `openMain(.settings(.general))`, `openReports()` → `openMain(.reports)`, add `package func openMain(_ page: MainPage)` and `package func openSettings(_ page: SettingsPage)`.
- Modify `Sources/SathiCore/Engine/Engine+TrackerAPI.swift` `openActivityReport(_:)`: `presenter.showMain(.activities(day))`; keep `trackerRuntime.reportDay` until Task 14 removes the need.
- Modify the UI callers that open settings for a topic: `Sources/SathiUI/Features/TimeBlock/TimeBlockCard.swift`, `Sources/SathiUI/Features/TimeBlock/WaitingSaveAction.swift`, `Sources/SathiUI/Features/Tracker/Prompts/TrackerCalendarRow.swift` (check each: the macOS "Open System Settings" link stays; only Sathi settings links change to `openSettings(.timeBlocks)` / `.tracker`).
- Modify `Sources/SathiUI/Windows/UIController.swift`: implement `showMain(_:)` for now by routing `.settings` to the existing `SettingsWindow` (with the matching `SettingsTab`) and `.today`/`.activities`/`.reports` to the existing `ReportsWindow`. Task 10 replaces this.
- Modify `Tests/SathiTestSupport/Fakes.swift`: `SpyPresenter.Call` gets `showMain(MainPage)`; remove `showSettings`, `showReports`.

Tests first:
- `Tests/SathiCoreTests/EngineMainPageTests.swift`: `openSettings()` records `.showMain(.settings(.general))`; `openReports()` → `.showMain(.reports)`; `openActivityReport(day)` → `.showMain(.activities(day))` and closes the end-of-day popup; `openSettings(.tracker)`.
- `Tests/SathiCoreTests/MainPageTests.swift`: `SettingsPage.all` order is General, Fota, Boi, Shanti, Shokti, Quick reminders, Activity tracker, Time blocks, Sound.
- Update the spy expectations in `Tests/SathiCoreTests/EngineReportScreenTests.swift`, `EngineFlowTests.swift`, `Tracker/Engine/EngineTrackerDayEdgeTests.swift`, `Tests/SathiUITests/MenuBarTests.swift`, `TimeBlockCardTests.swift`, `TimeBlockCardWaitingTests.swift`, `CalendarGoneAccessTests.swift`, `Tracker/Prompts/TrackerCalendarRowAccessTests.swift`, `SettingsSidebarTests.swift` from `.showSettings`/`.showReports` to the new calls (same meaning, new name; say so in the commit).

Acceptance: W1 at the Engine level. `grep -rn "showSettings\|showReports" Sources Tests` returns nothing.

Commands: `./scripts/test.sh EngineMainPageTests`, `./scripts/test.sh MainPageTests`, `./scripts/test.sh`, `./scripts/lint.sh`, `swift build`. Commit `refactor(app-window): one presenter call opens the main window on a page`.

### Task 6: Today screen model and `TodayModel` (Core)

Goal: the data of spec rules 10–15, with the once-a-minute publish rule.

Files:
- Create `Sources/SathiCore/Today/TodayScreen.swift`: `TodayScreen: Equatable` with `dateLine`, `greeting`, `now: TodayNow` (`.running(minutes, text, category, since, nextAsk)`, `.idle(nextAsk)`, `.off`), `buddies: [TodayBuddy]` (habit, total, goal, unit text, progress, `status: TodayBuddyStatus` = `.met`, `.dayOff`, `.off`, `.noReminder`, `.next(Date)`, `.gymSession(n, of, Date)`), `sofar: TodaySoFar` (segments, logged, top categories ≤ `Limits.todayCategoryRows`), `comingUp: [ComingUpItem]`.
- Create `Sources/SathiCore/Today/ComingUpList.swift`: pure `make(items:now:calendar:)` → sorted, today only, after now, max `Limits.comingUpMax`.
- Create `Sources/SathiCore/Engine/Engine+Today.swift`: `package var todayScreen: TodayScreen` built from `greeting`, `goalText`, `goalMet`, `progress`, the next due per habit (the same source the menu card's "Next at" uses; find it in `Engine+Display.swift` / `HabitCard` and reuse, do not copy), `trackerNextPopup`, `quickReminders`, day summary prefs and `LiveState.lastDaySummary`, `activityDay(today)`, `ActivityTimeline.segments`, `ActivityDayStats`. Times are cut to whole minutes.
- Create `Sources/SathiCore/Engine/TodayModel.swift`: `@MainActor package final class TodayModel: ObservableObject` with `@Published private(set) var screen`; `attach(_ engine:)` subscribes to `engine.objectWillChange` (`receive(on:)` main), rebuilds `todayScreen`, assigns only when it differs (the `StatusModel` pattern). Detach on deinit (no retain cycle).
- Modify `Sources/SathiCore/Constants/Limits.swift`: `comingUpMax = 6`, `todayCategoryRows = 4`.
- Create `Sources/SathiCore/Formatting/Copywriter+Today.swift`: date line, "Next at {time}", "Session {n} of {m} at {time}", "Still on it?", "What now?", "Fota · water" item names, "Day summary", "Nothing more today.", "Not tracking now", "Activity tracker is off", "{length} logged".

Tests first:
- `Tests/SathiCoreTests/ComingUpListTests.swift`: sort, today only, past items out, max 6.
- `Tests/SathiCoreTests/EngineTodayScreenTests.swift`: running activity → `.running` with next ask; tracker off → `.off`; water met → `.met` and not in Coming up; a day off; gym session text; quick reminder due today in Coming up, tomorrow not; day summary item only when on and not shown today.
- `Tests/SathiCoreTests/TodayModelTests.swift`: with a `FakeClock`, 10 engine ticks inside 1 minute (a running breathing session, 1 s ticks) publish 0 times; crossing the minute publishes 1 time; logging a glass publishes at once. Count with a `sink` on `$screen.dropFirst()`.

Acceptance: T2, T3 pass.

Commands: `./scripts/test.sh ComingUpListTests`, `./scripts/test.sh EngineTodayScreenTests`, `./scripts/test.sh TodayModelTests`, `./scripts/test.sh SathiCoreTests`, `./scripts/lint.sh`, `swift build`. Commit `feat(app-window): Today screen model, published once a minute`.

### Task 7: Activity prompt model and engine changes (Core)

Goal: spec rules 41, 45, 46, 50, 52, 54 in Core. The UI comes in Task 8.

Files:
- Create `Sources/SathiCore/Tracker/PromptReason.swift`: `package enum PromptReason { ask, shortcut, ends, back, event }` with `init(_ kind: PromptKind)` (exhaustive map of spec rule 41).
- Create `Sources/SathiCore/Tracker/ActivityPromptScreen.swift` and `ActivityPromptBuilder.swift`: from `TrackerPromptState` build `reason`, `tag`, `timeText`, `title`, `message`, `showsWhere`, `keep: PromptKeep?` (`.continueLast(text)`, `.keep(text)`, `.keepGoing(minutes)`, `.stillOnLate`, `.backTo(text)`), `startLabel`, `skip: PromptSkip`, `startedChoices: [Date]` (empty → link hidden), `fixedStart: Date?` (event), `calendarNote`, `showsIWasHere`. Pure, no side effects; `TrackerPromptState` already carries what it needs (add fields only if a test proves one is missing, for example `away.cause`).
- Create `Sources/SathiCore/Formatting/Copywriter+ActivityPrompt.swift`: every tag, title, message, button label, and calendar note of spec rules 41, 46, 49, 52 (exact words from the spec).
- Modify `Sources/SathiCore/Engine/Engine+TrackerPromptState.swift`: switch times per reason (spec rule 50): `stillOnIt` and `center` while running → from `running.lastAnswer` (or `start`); `welcomeBack` → from the Away end; `whatNow` keeps `switchFrom`. Keep the file under 200 lines (move helpers to `Engine+TrackerPromptTimes.swift`).
- Leave `PromptKind.isCorner` in place; Task 9 deletes it together with its only user in `UIController+Tracker.swift`, so every task builds.
- Modify `Sources/SathiCore/Engine/Engine+TrackerLoop.swift` `showTrackerEndOfDayIfDue`: when `data.live.tracker.prompt != nil`, wait; show at the first tick after the prompt clears (still 1 time a day, `lastEndOfDay` set only on show).
- Add the keyboard rule in Core so the UI has no logic: `package var trackerPromptTakesKeyboard: Bool { trackerPrompt != nil && trackerPromptByUser }` in `Engine+TrackerReportAPI.swift` (or a new `Engine+TrackerKeyboard.swift`).

Tests first:
- `Tests/SathiCoreTests/Tracker/Prompts/ActivityPromptBuilderTests.swift` (`@Test(arguments: PromptKind.allCases)`): reason, tag, color key, title, start label, keep, skip per row of spec rule 52; "ACTIVITY ENDED" vs "STILL ON IT?"; late message and `.stillOnLate`; shortcut with and without a running activity; back message by `AwayCause`; event: fixed start, no Started link, read-only calendar note.
- `Tests/SathiCoreTests/Tracker/Engine/EnginePromptStartedTests.swift`: Started choices for ends (from last answer), back (from Away end), shortcut while running; Start with a picked time in the ends prompt ends the old activity and starts the new one at the same second (P6, phase 17 G13).
- `Tests/SathiCoreTests/Tracker/Engine/EngineEndOfDayWaitTests.swift`: end of hours with a prompt open → no end-of-day; prompt skipped → end-of-day shows at the next tick; shows only 1 time.
- `Tests/SathiCoreTests/Tracker/Engine/EnginePromptKeyboardTests.swift`: scheduled `whatNow`, `stillOnIt`, `welcomeBack`, `eventAsk` → false; `openTrackerPanel()` and `doneActivity()` → true.
- Run every existing test under `Tests/SathiCoreTests/Tracker/` unchanged (P7).

Acceptance: P1 (model part), P5 (rule part), P6, N1 (engine part) pass; no existing tracker Core test changed.

Commands: `./scripts/test.sh ActivityPromptBuilderTests`, `./scripts/test.sh EnginePromptStartedTests`, `./scripts/test.sh EngineEndOfDayWaitTests`, `./scripts/test.sh EnginePromptKeyboardTests`, `./scripts/test.sh SathiCoreTests`, `./scripts/lint.sh`, `swift build`. Commit `feat(app-window): one activity prompt model with 5 reasons`.

### Task 8: Activity prompt view (UI)

Goal: the view of spec rules 46–51 (`ActivityPrompt.dc.html`), replacing the 5 prompt views.

Files:
- Modify `Sources/SathiUI/Theme/NightPalette.swift`: `promptAsk` `#FF8A80` (= `tracker`), `promptShortcut` `#A99CF5`, `promptEnds` `#FFC94A`, `promptBack` `#5FD39A`, `promptEvent` `#7FB8FF` (= `trackerEvent`), `promptHeader` `#161D2C` (= `trackerInset`), `promptCard` `#1A2233`, `promptCardLine` `#263049`, `promptBoxLine` `#2C3650`, `promptBox` `#121826` (= `trackerWell`). Add `Night.reason(_ r: PromptReason) -> Color` (exhaustive). Split into `NightPalette+Prompt.swift` if needed.
- Create `Sources/SathiUI/Constants/UIMetrics+ActivityPrompt.swift`: width 880, header top bar 4, icon tile, pane widths, card padding 11×12 / radius 12, box height 34 / radius 6 / padding 12, text field height 50 / radius 12, row label width, footer button sizes, `recentKeys = 6` (from `Limits.recentShown`).
- Modify `Sources/SathiCore/Constants/Limits.swift`: `recentShown = 6` (`recentMax` stays 10).
- Create in `Sources/SathiUI/Features/Tracker/Prompt/` (one view per file): `ActivityPromptView` (root, takes `TrackerPromptState`, builds `ActivityPromptScreen`), `PromptHeader`, `PromptWhereBoxes`, `PromptRecentPane`, `PromptRecentCard`, `PromptForm` (text field + rows), `PromptBoxRow` (generic square boxes), `PromptCategoryBoxes`, `PromptCalendarBoxes` (reuse access states from `TrackerCalendarRow`), `PromptQuietRow`, `PromptStartedLink`, `PromptFooter`, `PromptKeys` (Enter, Esc, ⌘1–⌘6 via `.keyboardShortcut`).
- Modify `Sources/SathiUI/Windows/TrackerPromptContent.swift`: body is `ActivityPromptView(state:)` for every kind.
- Delete when no file uses them (after `swift build` shows no user): `WhatNowPopup`, `CenterPromptView`, `StillOnItPopup`, `WelcomeBackView`, `WelcomeBackParts`, `WelcomeForm`, `WelcomeWhileAway` (move its event rows into `PromptWhereBoxes` or keep it if reused), `EventAskPopup`, `TrackerRecentMenu`, `TrackerCategoryMenu`, `TrackerOptionsBox`, `TrackerSwitchRow`, `TrackerDraftForm`, `TrackerFormRows` and the other `Features/Tracker/Prompts/` files that become unused. Keep `TrackerNoteView` and `TrackerCalendarRow` logic that the new views reuse. `TrackerMenuCard` stays until Task 15.

Tests first (in `Tests/SathiUITests/Tracker/Prompt/`, reuse `PromptTestSupport.swift`):
- `ActivityPromptReasonTests.swift` (`@Test(arguments: PromptKind.allCases)`): tag text, title, Start label, Keep label presence, ✕ present.
- `ActivityPromptBoxesTests.swift`: no `Menu`/`Picker` in the tree (`findAll(ViewType.Menu.self)` is empty); every category, length, ask offset, and calendar + "None" is a button; quiet switch disabled for Open.
- `ActivityPromptRecentTests.swift`: 6 cards + "Show all 10"; a tap fills text and category and does not call `start` (spy `TrackerPromptActions`); ⌘ key labels.
- `ActivityPromptActionsTests.swift`: each footer button calls the mapped action of spec rule 52 (spy actions), including event Start → `pickEventCategory` then `answerEvent(true)`, back Keep → `backToLast`, "I was here" only after idle.
- `ActivityPromptWhereTests.swift`: where boxes only for back; a tap calls `pickPlace`; "+ Place" adds.
- Replace the old prompt tests in `Tests/SathiUITests/Tracker/Prompts/` (`WhatNowPopupTests`, `WhatNowSwitchTests`, `OtherPromptTests`, `PromptRedesignTests`, `PromptFixRoundTests`, `CenterPromptHeaderTests`, `TrackerRecentMenuTests`, `TrackerCategoryMenuTests`, `TrackerPopupOptionsTests`, `WelcomeBack*Tests`, `CalendarPopupRedesignTests`) with the new ones. For each deleted test, list in the commit message the new test that covers its requirement, or the spec rule that removed it (for example "recent pick starts at once" → spec rule 48).
- `Tests/SathiUITests/NightPaletteTests.swift`: a row for each reason color.

Acceptance: P1, P2, P3 pass. Render each reason to PNG with a temporary `WebsiteShots`-style test into the scratchpad, compare with `ActivityPrompt.dc.html` (kind = ask, shortcut, ends, back, event), fix gaps, then delete the temporary test.

Commands: `./scripts/test.sh SathiUITests`, `./scripts/test.sh`, `./scripts/lint.sh`, `swift build`. Commit `feat(app-window): one activity prompt view with 5 reasons`.

### Task 9: One centered prompt panel, notes and end of day at center (UI controller)

Goal: spec rules 42, 43, 45, 53, 54 in `UIController`.

Files:
- Modify `Sources/SathiUI/Windows/UIController+Tracker.swift`: `showTrackerPrompt(_:)` — when a prompt panel exists, replace its hosting root view in place (`NSHostingView.rootView = …`, resize around the same center), never close and reopen; when none exists, create it centered on the mouse display. Keyboard: take it only when `engine.trackerPromptTakesKeyboard` (Task 7); remove `trackerPromptTakesKeyboard(_:byUser:)` and `cancelAction`. Esc maps to Skip inside the view (Task 8), so the panel needs no cancel closure.
- Modify `Sources/SathiUI/Windows/UIController+TrackerPanels.swift`: remove `placeTrackerCorner`, `isTrackerCorner`, `trackerCorner`; keep `presentTrackerCentered` and resize watching. Add the note placement: above the open prompt with `UIMetrics.centerStackGap`, else below, else plain center.
- Create `Sources/SathiUI/Windows/CenterStack.swift`: pure `noteOrigin(note: CGSize, prompt: CGRect?, screen: CGRect, gap:) -> CGPoint` and `mouseScreenFrame(screens:mouse:) -> CGRect`.
- Modify `Sources/SathiUI/Windows/UIController.swift`: remove `trackerCorner` from stored vars; `showTrackerNote` uses the center placement. `UIController+Placement.swift` `presentCentered` uses the mouse display (check what it uses now; change only if it is not the mouse display).
- Modify `Sources/SathiCore/Tracker/PromptKind.swift`: delete `isCorner` and fix every user.
- Check `Sources/SathiUI/Windows/UIController+Corner.swift` and `restack()` no longer touch tracker panels.

Tests first:
- `Tests/SathiUITests/CenterStackTests.swift`: note above the prompt, below when no room, center with no prompt; the mouse screen pick with 2 screens.
- Update `Tests/SathiUITests/Tracker/Integration/TrackerPresenterTests.swift` and `TrackerPresenterFixTests.swift`: the keyboard checks move to `engine.trackerPromptTakesKeyboard` (rule change: welcome back no longer takes the keyboard, spec rule 45; say so in the commit). Add: showing `.stillOnIt` while `.whatNow` is open keeps the same `trackerPromptPanel` object (identity check `===`).
- `Tests/SathiUITests/CornerStackTests.swift`: a tracker prompt is never in `corner`.

Acceptance: P4, P5, N1 pass. Manual: a scheduled prompt does not steal typing; the shortcut gives the keyboard; a second reason swaps content in place.

Commands: `./scripts/test.sh CenterStackTests`, `./scripts/test.sh TrackerPresenterTests`, `./scripts/test.sh SathiUITests`, `./scripts/lint.sh`, `swift build`. Commit `feat(app-window): one centered prompt panel; notes and end of day at center`.

### Task 10: Main window shell, Dock icon, launch and close

Goal: spec rules 1–9 and W2–W5. The pages show the old content for now (Settings view, Reports view, a placeholder Today and Activities); Tasks 11–14 fill them.

Files:
- Create `Sources/SathiUI/Windows/MainWindow.swift`: builds the `NSWindow` (`UIMetrics.mainWindowSize`, min size, styles of spec rule 1, dark, `isReleasedWhenClosed = false`, delegate `WindowCloseWatcher`), root `MainView(route:)`.
- Create `Sources/SathiUI/Features/Main/MainRoute.swift` (`ObservableObject` with `@Published var page: MainPage`, owned by `UIController`, so `showMain` can change the page of an open window), `MainView.swift` (sidebar + page switch), `MainSidebar.swift`, `MainSidebarItem.swift`, `SettingsSubnav.swift` (nested pages, rule 3), `TrackerStatusBlock.swift` (rule 2).
- Create `Sources/SathiUI/Windows/UIController+Main.swift`: `showMain(_ page:)` (create or reuse the window, set `route.page`, `NSApp.setActivationPolicy(.regular)`, activate, `makeKeyAndOrderFront`), `mainWillClose()` (`contentView = nil`, drop window and route, `setActivationPolicy(.accessory)`).
- Create `Sources/SathiUI/Windows/DockPolicy.swift`: pure `static func policy(mainWindowOpen: Bool) -> NSApplication.ActivationPolicy`.
- Delete `Sources/SathiUI/Windows/SettingsWindow.swift`, `Sources/SathiUI/Windows/ReportsWindow.swift`, the `settings`/`reports` vars and close watchers in `UIController.swift`, and `OpenReportsRow` in `SettingsSidebar.swift` (the main sidebar has Reports).
- Create `Sources/SathiUI/Constants/UIMetrics+MainWindow.swift`: window size 1200 × 760, min size, sidebar width, item heights, paddings from the mockups.
- Create `Sources/Sathi/LaunchKind.swift`: pure `static func isLoginItem(propData: OSType?) -> Bool` (compare with `keyAELaunchedAsLogInItem`).
- Modify `Sources/Sathi/AppDelegate.swift`: in `applicationDidFinishLaunching` read `NSAppleEventManager.shared().currentAppleEvent?.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue`; not a login item → `engine.openMain(.today)`. Add `applicationShouldHandleReopen(_:hasVisibleWindows:)` → `openMain(.today)`, return `false`. Keep the `flush()` calls in `applicationWillTerminate`.
- Check `Resources/Info.plist`: `LSUIElement` stays `true`. Check that ⌘Q and ⌘W work while `.regular` (the SwiftUI default app menu); if not, add a minimal main menu in `Sources/Sathi/AppMenu.swift` with "Quit Sathi" (⌘Q) and "Close" (⌘W).

Tests first:
- `Tests/SathiUITests/DockPolicyTests.swift`: open → `.regular`, closed → `.accessory`.
- `Tests/SathiUITests/MainSidebarTests.swift`: 4 page items; with `.settings(_)` the 9 sub-pages in the order of spec rule 3; tracker status block ON/OFF texts; a tap on an item sets `route.page`.
- `Tests/SathiUITests/MainViewTests.swift`: `.settings(.tracker)` shows `TrackerSettingsPage`; `.reports` shows the reports content.
- `LaunchKind` test: add `Tests/SathiUITests/LaunchKindTests.swift` only if the executable target is testable; else move `LaunchKind` to `Sources/SathiUI/Windows/LaunchKind.swift` (`package`) and test it there.
- Replace `Tests/SathiUITests/SettingsWindowTests.swift` with `MainWindowTests.swift` (window style mask, min size, `isReleasedWhenClosed == false`).

Acceptance: W1–W5. Manual (write the steps in the commit body): launch from Finder → Today + Dock icon; ⌘W → Dock icon gone, menu bar stays; ⌘Q quits; enable "Open Sathi when I log in", log out and in → no window (or record Q3 result).

Commands: `./scripts/test.sh SathiUITests`, `./scripts/test.sh`, `./scripts/lint.sh`, `swift build`, then ask the user and run `./build.sh --install` and `./scripts/perf.sh`. Commit `feat(app-window): main window with sidebar, Dock icon only while open`.

### Task 11: Settings pages in the main window

Goal: spec rules 20–26.

Files:
- Modify `Sources/SathiUI/Features/Settings/SettingsView.swift`: becomes `SettingsPageView(page: SettingsPage)` (no own sidebar, no fixed window size), page header (eyebrow "SETTINGS", title, buddy On switch), content, footer "Settings save at once.".
- Delete `Sources/SathiUI/Features/Settings/SettingsTab.swift` (replaced by Core `SettingsPage`), `SettingsSidebar.swift`, `SidebarNavButton.swift`, `MyDayGroup.swift`, `AddBuddyTab.swift`, `MadeByFooter.swift` (move the made-by footer and version text to the main sidebar bottom if the mockup has room; else to General), when unused.
- Create `Sources/SathiUI/Features/Settings/SettingsHeader.swift`, `QuickRemindersPage.swift` (`QuickSettingsCard` + the `QuickListCard` rows with Delete + "+ Quick reminder"), `SoundPage.swift` ("Play soft sounds" + `MeditationSoundCard`).
- Modify `Sources/SathiUI/Features/Settings/GeneralTab.swift`: remove `QuickSettingsCard()`; modify `BehaviourCard.swift`: remove the sound row. Modify `Sources/SathiUI/Features/Meditation/MeditationSettingsTab.swift`: replace the sound card with the link line of spec rule 23 (`openSettings(.sound)`).
- Add copy to `Sources/SathiCore/Formatting/Copywriter+Settings.swift` (new): page titles ("Fota · water", …, "Quick reminders", "Sound"), "Settings save at once.", "Session sound is on the Sound page.".

Tests first:
- `Tests/SathiUITests/SettingsPagesTests.swift` (`@Test(arguments: SettingsPage.all)`): each page shows its title and its main card; buddy pages have the On switch bound to `enabledBinding`.
- `Tests/SathiUITests/QuickRemindersPageTests.swift`: pending reminders listed, Delete removes (`h.engine.quickReminders`).
- `Tests/SathiUITests/SoundPageTests.swift`: the General sound switch and the session sound card.
- Update `GeneralTabTests`, `GeneralTabDaySummaryTests`, `MeditationSettingsTabTests`, `MeditationSoundCardTests`, `QuickSettingsCardTests`, `SettingsViewTests`, `SettingsSidebarTests`, `SettingsTabWidthTests`, `TimeBlockSettingsSidebarTests` to the new places (or delete when the sidebar is gone, naming the replacing test).

Acceptance: S1, W5 pass. Compare with `Settings.dc.html`.

Commands: `./scripts/test.sh SathiUITests`, `./scripts/lint.sh`, `swift build`. Commit `feat(app-window): settings pages in the main window; Quick reminders and Sound pages`.

### Task 12: Today page

Goal: spec rules 10–15 view (`Main.dc.html`).

Files:
- Create in `Sources/SathiUI/Features/Today/`: `TodayPage` (owns a `@StateObject TodayModel`, attaches to the engine on appear, detaches on disappear), `TodayHeader`, `TodayNowCard`, `TodayBuddyCard`, `TodayBuddyGrid`, `TodaySoFarCard` (reuse `ActivityRibbon`/`ActivityAxis` from `Features/Reports/Activities/` for the strip), `TodayComingUp`.
- Create `Sources/SathiUI/Constants/UIMetrics+Today.swift`.
- Modify `Sources/SathiUI/Features/Main/MainView.swift`: `.today` → `TodayPage`.
- Buttons: Quick reminder → `e.openQuickAdd()`; Take a break → reuse `BreakMenu`; Switch → `e.openTrackerPanel()`; Stop → `e.doneActivity()`; Log activity → `e.openTrackerPanel()`; Turn on → `e.openSettings(.tracker)`; Breathe now → the existing start-session action for meditation.

Tests first:
- `Tests/SathiUITests/TodayPageTests.swift`: build `TodayScreen` states directly (ViewInspector does not run `onAppear`): running Now card texts and Switch/Stop calls; idle and off cards; 4 buddy cards with "✓ Goal met", "Next at", gym session text, "Breathe now" only for Shanti; Coming up rows and "Nothing more today."; Today so far off text.
- No repeating timer: `grep -rn "Timer\|TimelineView" Sources/SathiUI/Features/Today` returns nothing (note it in the commit).

Acceptance: T1 passes. Compare with `Main.dc.html`. `/perf-check` after install: CPU with the main window on Today < 10%, idle after close ~0%.

Commands: `./scripts/test.sh TodayPageTests`, `./scripts/test.sh SathiUITests`, `./scripts/lint.sh`, `swift build`. Commit `feat(app-window): Today page`.

### Task 13: Reports page with ranges

Goal: spec rules 28, 30–35 view (`Reports.dc.html`).

Files:
- Create `Sources/SathiUI/Features/Ranges/RangeBar.swift` (segment Day/Week/Month + ‹ title › using `StatsRange` and `Copywriter.rangeTitle`; › disabled by `canGoForward`), `RangeChangeText.swift`.
- Create in `Sources/SathiUI/Features/Reports/`: `ReportsPage` (`@State var range: StatsRange`, selected buddy), `BuddyTotalCard`, `BuddyTotalsRow`, `GoalDaysChart` (Swift Charts bars, no animation loop), `CategoryTimeCard`, `ReportsExportButton` (calls `exportHistory(range, to: Downloads)` then `NSWorkspace.activateFileViewerSelecting`; failure text).
- Modify `Sources/SathiUI/Features/Reports/HabitReportsView.swift` (and its chart, calendar, facts files) to take a `StatsRange` and `engine.reportScreen(range, selected:)` (Task 3), shown as the detail under the cards on a tap.
- Delete `Sources/SathiUI/Features/Reports/ReportsView.swift`, `ReportsTabBar.swift` (`ReportsTab`, `ActivityRange`), `ReportsHeader.swift`, `RangeSegment.swift`, `HabitTileView.swift` when unused (Activities becomes its own page).
- Modify `Sources/SathiUI/Constants/UIMetrics+Reports.swift`: sizes from the mockup; remove `reportsSize`.

Tests first:
- `Tests/SathiUITests/RangeBarTests.swift`: titles, › disabled on the current range, ‹ moves back, kind change keeps the day.
- `Tests/SathiUITests/ReportsPageTests.swift`: 4 cards with total, change line, "goal met m of n days"; off buddy dimmed; a tap shows the detail chart; category card rows with change; export button present.
- Update `ReportsTests.swift`, `ReportsPartsTests.swift`, `StreakCellTests.swift` to the page (name each changed test in the commit).

Acceptance: R1 (view), R4, R5, R6 (manual: file in Downloads, Finder shows it, no save panel). Compare with `Reports.dc.html`.

Commands: `./scripts/test.sh RangeBarTests`, `./scripts/test.sh ReportsPageTests`, `./scripts/test.sh SathiUITests`, `./scripts/lint.sh`, `swift build`. Commit `feat(app-window): Reports page with Day, Week, Month and compare`.

### Task 14: Activities page with ranges

Goal: spec rules 36–40 view (`Activities.dc.html`).

Files:
- Create `Sources/SathiUI/Features/Reports/Activities/ActivitiesPage.swift` (`RangeBar` + content; `.activities(day)` from the route opens that day in the Day range), `ActivityRangeView.swift` (Week/Month: tiles with change, day rows, category totals with change, Copy card), `ActivitiesExportButton.swift`.
- Modify `ActivityReportsView.swift`, `ActivityDayView.swift`, `ActivityMonthView.swift`, `ActivityDayHeader.swift`, `ActivityDatePicker.swift`: Day keeps the log, edit, fill, add past, totals, and standup text; the month view becomes the range view; the date picker stays for Day only if the mockup keeps it (it does not: ‹ › replace it; delete it when unused).
- Modify `Sources/SathiCore/Engine/Engine+TrackerReportAPI.swift`: remove `reportDay` / `takeActivityReportDay()` once `MainPage.activities(DayKey?)` carries the day (and `trackerRuntime.reportDay`).
- Modify `Sources/SathiUI/Features/Main/MainView.swift`: `.activities(day)` → `ActivitiesPage(day:)`.

Tests first:
- `Tests/SathiUITests/Tracker/Reports/ActivitiesPageTests.swift`: Day shows the log rows and standup Copy; Week shows 7 day rows and tiles with change lines; a day row tap switches to that Day; tracker off text and "Turn on"; export button present.
- Update `ActivityDayViewTests`, `ActivityMonthViewTests`, `Tracker/Integration/TrackerReportsWiringTests.swift` (the end-of-day "Open full report" now records `.showMain(.activities(day))`).

Acceptance: A1, R6 (manual export). Compare with `Activities.dc.html`.

Commands: `./scripts/test.sh ActivitiesPageTests`, `./scripts/test.sh SathiUITests`, `./scripts/test.sh`, `./scripts/lint.sh`, `swift build`. Commit `feat(app-window): Activities page with Day, Week, Month and export`.

### Task 15: Quick panel

Goal: spec rules 16–19 (`QuickPanel.dc.html`).

Files:
- Modify `Sources/SathiUI/Features/MenuBar/MenuPanel.swift`: new content: `QuickHeader`, `QuickNowRow`, (`TimeBlockCard` while a block runs or waits), `NapBanner` while paused, `QuickBuddyRow` × 4, `QuickActionRow` (Quick reminder, Take a break via `BreakMenu`, Time block per Q1), `OpenSathiButton`, `QuickLinks` (Reports, Settings, Quit). Width `UIMetrics.quickPanelWidth`. Keep `MenuWindowFit` sizing and the `onAppear` tick.
- Create those views in `Sources/SathiUI/Features/MenuBar/` (one per file) and `Sources/SathiUI/Constants/UIMetrics+QuickPanel.swift`.
- "Open Sathi", "Reports", "Settings" call `openMain`/`openReports`/`openSettings` and close the panel (dismiss the `MenuBarExtra` window: `NSApp.keyWindow?.close()` from a small helper, or the `dismiss` environment action if it works with `.window` style; test both by hand).
- Delete when unused: `HabitList`, `HabitCard`, `SleepingRow`, `MenuHeader`, `MenuFooter`, `MenuCards`, `ToolRow`, `TrackerMenuCard` (and `TrackerMenuSlot`), `GoalMetBadge`/`ProgressRing` only if no other user, `QuickListCard` (moved in Task 11). Keep Engine display APIs that Today or the quick panel use.

Tests first:
- `Tests/SathiUITests/QuickPanelTests.swift`: Now row with Switch → `openTrackerPanel` (spy prompt set); idle row with Log activity; 4 buddy rows with the status texts; "+1 glass" logs 1 glass (`h.engine.glassesToday` +1); Open Sathi / Reports / Settings → `.showMain(.today/.reports/.settings(.general))`; time block card only while a block runs.
- Update or replace `MenuBarTests`, `MenuGlanceHeightTests`, `MenuPanelHeightTests`, `HabitCardTests`, `HabitCardGoalMetTests`, `HabitCardUpNextTests`, `HabitListTests`, `ToolRowTests`, `QuickListCardTests`, `Tracker/Settings/TrackerMenuCardTests.swift`, `Tracker/Integration/TrackerMenuWiringTests.swift`; name each replaced test and its new home in the commit.

Acceptance: Q1, Q2. Compare with `QuickPanel.dc.html`. After install: open and close the panel, `./scripts/perf.sh` CPU back to ~0%.

Commands: `./scripts/test.sh QuickPanelTests`, `./scripts/test.sh SathiUITests`, `./scripts/test.sh`, `./scripts/lint.sh`, `swift build`. Commit `feat(app-window): short quick panel opens the main window`.

### Task 16: Docs, website shots, and Definition of done

Goal: close the phase.

Files:
- Modify `CLAUDE.md`: the intro paragraph (main window, quick panel, one activity prompt, ranges); the module map: `SathiCore/Today/`, `Stats/StatsRange(+Compare)`, `RangeChange`, `BuddyRange*`, `ActivityRange*`, `Export/ActivityRangeExporter`, `HistoryRangeExporter`, `Models/MainPage`, `Tracker/PromptReason`, `ActivityPrompt*`, `Engine+Today`, `TodayModel`, `Engine+Range*`; `SathiUI/Features/Main/`, `Today/`, `Ranges/`, `Tracker/Prompt/`, Windows `MainWindow`, `UIController+Main`, `DockPolicy`, `CenterStack`; remove `SettingsWindow`, `ReportsWindow`, the 5 prompt names, `TrackerMenuCard`; Constants `UIMetrics+MainWindow`, `+Today`, `+QuickPanel`, `+ActivityPrompt`. Commands table: `perf.sh --windows` now opens the main window.
- Modify `scripts/perf.sh` `--windows` prompts: ask the user to open and close the main window (Today, then Reports and Settings pages) in place of the 2 old windows.
- Modify `README.md`: features (main window, quick panel, activity prompt, ranges and export).
- Modify `docs/ROADMAP.md`: tick the Phase 18 boxes that pass; list what the user must still do.
- Website (`/sathi-website` skill): re-render the screenshots that show the menu, Settings, Reports, and tracker prompts (`SATHI_SHOTS="$PWD/site/screenshots" swift test --filter WebsiteShots`), update `Tests/SathiUITests/WebsiteShots*.swift` to the new views, update `site/index.html` text, run `./scripts/check-site.sh`.

Tests: `WebsiteShots*` compile and run.

Acceptance: D1. `swift build -c release` with no new warnings. Ask the user, then `./build.sh --install` and `./scripts/perf.sh` (idle < 1%, < 40 MB, < 10 wakeups/min); the user runs `./scripts/perf.sh --windows` in Terminal (< 50 MB, cycle 2 adds < 3 MB). Hand tests: every row of the spec "Acceptance criteria" marked Manual.

Commands: `./scripts/test.sh`, `./scripts/lint.sh`, `swift build -c release`, `./scripts/check-site.sh`. Commit `docs(app-window): module map, README, roadmap, website`.
