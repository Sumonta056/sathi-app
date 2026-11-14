# Phase 21 plan: Calendar page and manual merge

Goal: one experimental main-window page that shows calendar events and activities on one 6 AM to 6 AM time grid (Day, Week, Month), with create, edit and delete of events through the existing CalendarWriter. Plus a manual Merge of activities on the Activities page Day view, and later on the Calendar page Day view.

Spec: `docs/specs/phase-21-calendar-page.md`. The spec is the authority. Rule IDs (C1.2, M2.3, ...) refer to it.

## Global constraints

- No code comments (SwiftLint `no_comments`). One job per file. Max 200 lines per file, max 150 lines per type body. Split before the limit.
- No magic numbers. Behavior constants go in `SathiCore/Constants` (Limits, Timing, StorageKeys). Layout goes in `SathiUI/Constants/UIMetrics+*.swift`. Use new per-track extension files (pattern: `Limits+ActivitiesV2.swift`), so Limits.swift and Timing.swift are not edited.
- SathiCore never imports AppKit or SwiftUI. The outside world goes through `Sources/SathiCore/Ports/`. Each new port gets a fake in `Tests/SathiTestSupport/`.
- The Engine reads time only from `clock.now`. Never `Date()` in Engine, Stats or CalendarPage Core code. Tests use FakeClock and fixed dates, and never wait.
- `package` access for cross-target API. The rest is internal or private. `@MainActor` on everything that touches Engine or UI.
- Tests first (Swift Testing, ViewInspector 0.10). Expected values come from the spec. Never weaken a test.
- `.claude/rules/business-logic.md` changes before behavior changes (first task of each track).
- Storage never loses data. A Prefs change follows `.claude/skills/data-migration/SKILL.md` Recipe A: lenient decode, defaults, a decode test for old JSON.
- Perf budget: no repeating timer and no new Timer. Deadlines go through `upcomingDeadlines()` and the tick. The page redraws only on a store change, a range change, or `Engine.now` (changes at most 1 time per minute). Event reads cover only the visible range. `./scripts/perf.sh` passes.
- Checks per task: `./scripts/test.sh <Suite or Target>`, `./scripts/lint.sh`, `swift build`. Each task ends in one commit on its track branch. Commit without asking (user rule for feature branches). Never push, never touch `main`.

Exact values:
- `Limits.calendarPageDayStartHour = 6`
- `Limits.calendarMonthChipsShown = 3` (ruling)
- `Limits.calendarDisplayJoinGap: TimeInterval = 5 * 60`
- `Limits.calendarSlotMinutes = 15`
- `Limits.calendarNewEventMinutes = 30`
- `Limits.calendarGridHours = 24`
- Titles: `Limits.blockTitleMax` (60)
- `Timing.mergeUndoShow: TimeInterval = 30` (ruling)
- `Limits.manualMergeMinRows = 2`
- Automatic merge: `Timing.activityMergeGap` (60 s), unchanged.

## Rulings on spec gaps (put them in business-logic.md)

R1. A page event write, and an `EKEventStoreChanged` while the page is open, mark the tracker's event cache stale (`trackerCalendarRuntime.readAt = nil`). The tracker's event rules do not change. While the page is closed nothing listens (C5.2).
R2. `Timing.mergeUndoShow` = 30 s. `Limits.calendarMonthChipsShown` = 3.
R3. An event that is made again (rollback or undo) gets a new ID. Only that row's `eventID` changes to the new ID.
R4. The kept event's title after a merge is the merged row's text.
R5. Merge selection:
- An unselected work row between the selected rows blocks the merge (`rowBetween`).
- An unnamed Away row inside the selection is removed like one between.
- At least 2 selected rows must be work rows (`kind == .work`, no `sourceEventID`).
- The running activity cannot be selected.
R6. Hiding duplicates: an activity with `eventID == e.id` hides the event. An activity with `sourceEventID == e.id` hides only the occurrence that holds the activity's start (`EventRules.isLogged` semantics).
R7. All-day events go by their calendar date. They are not cut by the 6 AM window.
R8. "Today" is the page day that holds now (at 01:30 Thursday that is Wednesday). › has no future limit on the Calendar page.
R9. In the popover, an end time-of-day at or before the start time-of-day means the next date.
R10. Calendar page Day view: plain click on an activity opens the edit panel. ⌘-click toggles selection for Merge (I1).
R11. Time tracked = every activity kind except Away. Planned = the union of timed shown events (all-day excluded), also events hidden by a logged activity.
R12. The switch lives in Settings → General, section "Experimental". When it is off, `.calendar` shows Today. The last calendar used is `prefs.calendarPage.lastCalendarID`.
R13. Join (C3.5) joins only rows of the same kind. Away rows never join.

## Dependency map

- Track 1: C1 → C2 → C3 → C4 → C5 → C6 → C7. C8 needs C4. C9 needs C8. C10 needs C6 and C9.
- Track 2: M1 → M2 → M3 → M4 → M5.
- Shared files:
  - business-logic.md: Track 1 adds a "## Calendar page" section before "## Time" and edits Main window rule 2. Track 2 adds rule 11f after 11e.
  - Engine.swift: each track adds its own stored property lines.
  - No other shared edits.
- Integration: after both tracks merge into `feat/calendar-page`, I1, then I2.

## Track 1: Calendar page (worktree branch `feat/calendar-page-c`)

### Task C1: Business rules, Calendar page prefs, constants
Covers: C1.2 (switch storage), C4.2, C4.3, C4.4, C6.5 (storage), C2.5 constant.
Files:
- Change `.claude/rules/business-logic.md`.
  - Add "## Calendar page" before "## Time", with rules 1–14 that restate C1–C9 and rulings R1, R6–R13.
  - In "Main window" rule 2, add "Calendar (only when the Calendar page switch is on, after Activities, tag Experimental)".
- Create `Sources/SathiCore/CalendarPage/CalendarPagePrefs.swift`.
  - `package struct CalendarPagePrefs: Codable, Equatable, Sendable { package var isOn = false; package var hiddenCalendarIDs: Set<String> = []; package var lastCalendarID: String?; package init() }`.
  - Custom `init(from:)`: `isOn = c.lenient(.isOn, or: d.isOn)`, `hiddenCalendarIDs = c.lenientSet(.hiddenCalendarIDs, or: [])`, `lastCalendarID = c.lenient(.lastCalendarID, or: String?.none)`.
- Change `Sources/SathiCore/Models/Prefs.swift`: add `package var calendarPage = CalendarPagePrefs()`. In `init(from:)` add `calendarPage = c.lenient(.calendarPage, or: d.calendarPage)`.
- Create `Sources/SathiCore/Constants/Limits+CalendarPage.swift` with the 6 Calendar constants above.
Tests first: `Tests/SathiCoreTests/CalendarPage/CalendarPagePrefsTests.swift` (@Suite "Calendar page prefs").
- `oldPrefsWithoutCalendarPageLoadDefaults`: JSON `{"tracker":{"isOn":true}}` decodes to `calendarPage == CalendarPagePrefs()` and `tracker.isOn == true`.
- `roundTripKeepsEveryField`: `isOn true`, hidden `["a","b"]`, last `"work"`. Encode, then decode, gives an equal value.
- `badHiddenElementIsDropped`: `"hiddenCalendarIDs":["a",5],"isOn":true` decodes to `["a"]` and `isOn` stays true.
- `hiddenNotAListGivesEmptyAndKeepsOthers`: `"hiddenCalendarIDs":"x","isOn":true` decodes to `[]` and `isOn == true`.
- `calendarPageWrongTypeKeepsOtherPrefs`: `{"calendarPage":3,"general":{"name":"Ana"}}` decodes to defaults, and `general.name == "Ana"`.
- Add a case to `Tests/SathiCoreTests/FileStateStoreTests.swift`: a partial prefs file with only `calendarPage` keeps the other defaults.
Steps: rules doc, prefs struct, Prefs field, constants.
Checks: `./scripts/test.sh CalendarPagePrefsTests`, `./scripts/test.sh PrefsCodingTests`, lint, `swift build`.
Commit: `feat(calendar): calendar page rules, prefs, constants`.

### Task C2: Calendar-page day and range
Covers: C2.1, C2.2, C2.5, C2.6, C2.9 (grid weeks), R7, R8.
Files:
- Create `Sources/SathiCore/CalendarPage/CalendarPageDay.swift`: `package enum CalendarPageDay`.
  - `static func interval(of day: DayKey, calendar: Calendar) -> DateInterval`: 06:00 of the date to 06:00 of the next date. Use `calendar.date(bySettingHour: Limits.calendarPageDayStartHour, minute: 0, second: 0, of:)` so DST is right.
  - `static func key(holding date: Date, calendar: Calendar) -> DayKey`.
  - `static func hourStarts(of day: DayKey, calendar: Calendar) -> [Date]`: `Limits.calendarGridHours` items.
- Create `Sources/SathiCore/CalendarPage/CalendarPageRange.swift`: `package struct CalendarPageRange: Equatable, Sendable`.
  - Fields: `kind: ReportRange`, `days: [DayKey]`, `interval: DateInterval`.
  - `static func containing(_ date: Date, kind: ReportRange, calendar: Calendar) -> CalendarPageRange`. Build it from `StatsRange.containing(key(holding: date).start(in:), …)`, so the first-weekday rule is the same as Reports.
  - `previous`, `next` (no limit), `changed(to:now:)` (same rule as business rule Stats 14), `holds(_:)`, `monthWeeks: [[DayKey]]` (whole weeks from the first weekday), `inRange(_ day: DayKey) -> Bool`, `initialScrollRow(now: Date) -> Int` (row 0 = 6 AM).
Tests first:
`Tests/SathiCoreTests/CalendarPage/CalendarPageDayTests.swift`:
- `key(holding: Thu 2026-03-05 00:22)` gives Wed 03-04.
- `Thu 05:59:59` gives Wed.
- `Thu 06:00` gives Thu.
- `interval(Wed)` is Wed 06:00 ..< Thu 06:00.
- Europe/Berlin 2026-03-29: interval runs 06:00 to 06:00 local and lasts 23 h.
- `hourStarts.count == 24`. The first is 06:00. The last is 05:00 of the next date.
`Tests/SathiCoreTests/CalendarPage/CalendarPageRangeTests.swift`:
- Week containing Wed 2026-03-04 with `firstWeekday = 2`: days Mon 03-02 … Sun 03-08, interval Mon 06:00 ..< Mon 03-09 06:00.
- With `firstWeekday = 1`: Sun 03-01 … Sat 03-07.
- `next` of the range that holds now exists (no limit).
- Day `previous` and `next` move 1 date. Month `next` of March is April.
- March 2026 with Monday first: `monthWeeks` has 6 rows, the first starts Mon 02-23, the last ends Sun 04-05.
- `changed(to: .day)` from a week that holds now gives today's page day. From a past week it gives the first date.
- `initialScrollRow`: now Wed 10:15 in the Wed range gives 4. Now Thu 01:30 in the Wed range gives 19. A range that does not hold now gives 0.
Checks: `./scripts/test.sh CalendarPageDayTests`, `./scripts/test.sh CalendarPageRangeTests`, lint, build.
Commit: `feat(calendar): 6 AM page day and page ranges`.

### Task C3: Blocks, no duplicates, display join, overlap lanes
Covers: C2.3, C2.8, C3.1–C3.5, R6, R13.
Files:
- Create `Sources/SathiCore/CalendarPage/CalendarBlock.swift`.
  - `package enum CalendarBlockStyle: Equatable, Sendable { case event(colorHex: UInt32), activity(category: String?), away, joined(category: String?) }`.
  - `package enum CalendarBlockSource: Equatable, Sendable { case event(CalendarEventInfo), activity(Activity, running: Bool) }`.
  - `package struct CalendarBlock: Equatable, Identifiable, Sendable { id: String; title: String; interval: DateInterval; style: CalendarBlockStyle; source: CalendarBlockSource; isAllDay: Bool; activityIDs: [ActivityID] }`.
- Create `Sources/SathiCore/CalendarPage/CalendarBlockBuilder.swift`: `package enum CalendarBlockBuilder`.
  - `static func blocks(events: [CalendarEventInfo], activities: [Activity], running: Activity?, colors: [String: UInt32], joins: Bool) -> [CalendarBlock]`.
  - `static func hides(_ e: CalendarEventInfo, in activities: [Activity]) -> Bool`.
  - Style: an event is outline. A work, buddy or time block activity is filled by category. Away is `.away`. An activity with `sourceEventID` is `.joined`.
- Create `Sources/SathiCore/CalendarPage/CalendarDisplayJoin.swift`: `static func groups(_ activities: [Activity]) -> [[Activity]]`. Rows join when the trimmed text is equal (case-sensitive), the category is equal, the kind is equal and not Away, and the gap is 0 … `Limits.calendarDisplayJoinGap`.
- Create `Sources/SathiCore/CalendarPage/CalendarBlockLayout.swift`: `package struct CalendarPlacedBlock: Equatable { block; lane: Int; lanes: Int }`, `static func place(_ blocks: [CalendarBlock]) -> [CalendarPlacedBlock]`. Lanes are greedy within each overlap cluster. All-day blocks are excluded.
Tests first:
`Tests/SathiCoreTests/CalendarPage/CalendarBlockBuilderTests.swift`:
- An activity with `eventID "e1"` hides event e1, and 1 block remains.
- An activity with `sourceEventID "m1"` that starts inside m1 hides it.
- A repeating m1 occurrence on another day (same ID, start outside) still shows.
- Twins `t1` and `t2` with the titles "Standup" and "Standup " from 2 calendars give 2 blocks.
- Styles: an event gives `.event(colorHex of its calendar)`. A work activity gives `.activity("Focus")`. Away gives `.away`. A `sourceEventID` activity gives `.joined`.
- An all-day event gives `isAllDay == true`.
- The running activity is a block with `running: true`.
`Tests/SathiCoreTests/CalendarPage/CalendarDisplayJoinTests.swift`:
- "Spec" 10:00–10:30 and "Spec" 10:34–11:00, same category: 1 group with `activityIDs` count 2.
- A gap of 5:01 gives 2 groups.
- "spec" against "Spec" gives 2 groups.
- A different category gives 2 groups.
- 2 Away rows give 2 groups.
- `joins: false` (Day) keeps every row.
- The input array is unchanged (saved data unchanged).
`Tests/SathiCoreTests/CalendarPage/CalendarBlockLayoutTests.swift`:
- 2 overlapping blocks get lanes 0 and 1, `lanes 2`.
- A 3rd block after both ends gets lane 0, `lanes 1`.
- A chain A∩B, B∩C, A not ∩ C gives A lane 0, B lane 1, C lane 0, `lanes 2`.
Checks: the 3 suites, lint, build.
Commit: `feat(calendar): page blocks, dedupe, display join, lanes`.

### Task C4: Stats, month cells, engine page data, shown calendars
Covers: C1.3, C2.9, C3.1, C4.1–C4.4, C8.1–C8.3, C9.2, R11.
Files:
- Create `Sources/SathiCore/CalendarPage/CalendarPageStats.swift`.
  - `package struct CalendarCategoryTime: Equatable { name: String?; seconds: TimeInterval }`.
  - `package struct CalendarPageStats: Equatable { tracked: TimeInterval; planned: TimeInterval; byCategory: [CalendarCategoryTime] }`.
  - `static func make(events: [CalendarEventInfo], activities: [Activity], interval: DateInterval) -> CalendarPageStats`. Clip to the interval. Planned is the union of timed events.
- Create `Sources/SathiCore/CalendarPage/CalendarMonthCell.swift`.
  - `package struct CalendarMonthCell: Equatable { day: DayKey; chips: [CalendarBlock]; more: Int; tracked: TimeInterval; isToday: Bool; inRange: Bool }`.
  - `static func cells(range: CalendarPageRange, blocks: [CalendarBlock], activities: [Activity], today: DayKey, calendar: Calendar) -> [[CalendarMonthCell]]`.
- Create `Sources/SathiCore/Engine/Engine+CalendarPage.swift`.
  - `package struct CalendarPageData: Equatable { range: CalendarPageRange; allDay: [CalendarBlock]; blocks: [CalendarBlock]; stats: CalendarPageStats; monthCells: [[CalendarMonthCell]] }`.
  - `package func calendarPage(_ range: CalendarPageRange) -> CalendarPageData`.
  - It reads `calendarWriter.events(from: range.interval.start, to: range.interval.end, calendarIDs: shownCalendarIDs)` once, and only when `calendarAccess == .allowed` and the shown IDs are not empty.
  - Activities come from the stored rows of each midnight day touched, plus the running activity until `clock.now`.
  - It works with the tracker off.
- Create `Sources/SathiCore/Engine/Engine+CalendarPageCalendars.swift`.
  - `package struct ShownCalendar: Equatable { choice: CalendarChoice; isShown: Bool }`.
  - `package struct ShownCalendarGroup: Equatable { account: String; calendars: [ShownCalendar] }`.
  - `package func shownCalendarGroups() -> [ShownCalendarGroup]` uses `readableCalendars()`.
  - `var shownCalendarIDs: [String]`.
  - `package func setCalendarShown(_ id: String, _ shown: Bool)` changes only `prefs.calendarPage.hiddenCalendarIDs`.
  - `package func setCalendarPageOn(_ on: Bool)`.
- Change `Sources/SathiCore/Engine/RangeMemo.swift`: add `value(_ request:, end: Date, engine:, build:)`. The existing method calls it with `range.interval.end`. `rangeInputs` takes `end: Date`.
Tests first:
`Tests/SathiCoreTests/CalendarPage/CalendarPageStatsTests.swift`:
- Events 10:00–11:00 and 10:30–11:30 give planned 90 min.
- An all-day event is excluded.
- Work 10:00–10:45, Away 10:45–11:00, buddy 11:00–11:10 give tracked 55 min.
- Interval Wed 06:00–Thu 06:00 with a row Thu 05:30–06:30 counts 30 min.
- A row Wed 05:00–07:00 counts 60 min.
- `byCategory` is sorted longest first.
`Tests/SathiCoreTests/CalendarPage/CalendarMonthCellTests.swift`:
- 5 events on a date give 3 chips and `more 2`.
- Tracked of a page day uses the 6 AM boundary.
- Today is flagged.
- A date outside the month has `inRange false` and no chips.
`Tests/SathiCoreTests/CalendarPage/EngineCalendarPageDataTests.swift`:
- With the tracker off, events show and there are no activity blocks.
- The read interval equals `range.interval` (`calendarWriter.eventReads.last`).
- With access `.denied` there is no read and the data is empty.
- An activity with `eventID` hides its event end to end.
- A row Thu 00:22–02:02 is in the Wed day range.
`Tests/SathiCoreTests/CalendarPage/EngineShownCalendarsTests.swift`:
- Every readable calendar is shown at first.
- Hide "home": `hiddenCalendarIDs == ["home"]`, home events do not show, and `tracker.readCalendarIDs` is unchanged.
- Changing `tracker.readCalendarIDs` does not change `hiddenCalendarIDs`.
- A new readable calendar "new" shows.
- Groups by account: "Gmail" [Gmail Work], "iCloud" [Home].
Checks: the 4 suites, `./scripts/test.sh SathiCoreTests`, lint, build.
Commit: `feat(calendar): page data, stats, month cells, shown calendars`.

### Task C5: Store-change port and page sync
Covers: C5.1–C5.3, C9.1, R1.
Files:
- Create `Sources/SathiCore/Ports/CalendarChangeSource.swift`.
  - `@MainActor package protocol CalendarChangeSource: AnyObject { func start(_ onChange: @escaping @MainActor () -> Void); func stop() }`.
  - `package final class NoCalendarChangeSource: CalendarChangeSource`.
- Create `Tests/SathiTestSupport/FakeCalendarChangeSource.swift`: `starts`, `stops`, `isListening`, `fire()`.
- Change `Sources/SathiCore/Engine/Engine.swift`.
  - Add the stored `let calendarChanges: CalendarChangeSource` and `var calendarPageOpen = false`.
  - Add the init param `calendarChanges: CalendarChangeSource = NoCalendarChangeSource()` after `hotkeys`.
- Change `Tests/SathiTestSupport/EngineHarness.swift`: add `package let calendarChanges: FakeCalendarChangeSource` and pass it to the Engine.
- Create `Sources/SathiCore/Engine/Engine+CalendarPageSync.swift`.
  - `package func calendarPageOpened()`: starts the source once, calls `refreshCalendarAccess()` and `storesChanged()`.
  - `package func calendarPageClosed()`: stops the source.
  - `func calendarStoreChanged()`: guard that the page is open, then `refreshCalendarChoices()`, `markTrackerEventsStale()`, `storesChanged()`, `requestTick()`.
  - `func markTrackerEventsStale()`: sets `trackerCalendarRuntime.readAt = nil`.
- Create `Sources/SathiUI/Platform/EventKitCalendarChangeSource.swift`: observes `.EKEventStoreChanged` (object nil, main queue). `stop` removes the observer.
- Change `Sources/Sathi/AppEnvironment.swift`: pass `calendarChanges: EventKitCalendarChangeSource()`.
Tests first: `Tests/SathiCoreTests/CalendarPage/EngineCalendarPageSyncTests.swift`.
- `closedPageDoesNotListen`: `!isListening`.
- `openStartsOnceAndCloseStops`: open 2 times gives `starts 1`. Close gives `stops 1`.
- `changeWhileOpenRebuildsTheMemo`: a RangeMemo build counter goes 1 to 2 after `fire()`, and the new event is in the data.
- `changeMarksTrackerEventsStale`: tracker reads "work". An event at 14:00 is added to the spy after the first read. `fire()`, then advance to 14:00. The event is logged in `.logAndTell`.
- `openingAddsNoTimer`: `nextTickDelay()` is equal before and after open.
- `afterCloseAFireDoesNothing`.
Checks: the suite, `./scripts/test.sh SathiCoreTests`, `./scripts/test.sh SathiUITests`, lint, build.
Commit: `feat(calendar): calendar change source and page sync`.

### Task C6: Event form and create, edit, delete
Covers: C6.1–C6.9, R9, R12 (last calendar).
Files:
- Change `Sources/SathiCore/Ports/CalendarEventInfo.swift`.
  - Add `isRepeating: Bool = false` and `hasGuests: Bool = false` (init defaults).
  - Add `package var isReadOnlyInSathi: Bool { isRepeating || hasGuests }`.
- Change `Sources/SathiUI/Platform/EventKitCalendarReaderMapping.swift`: `isRepeating: event.hasRecurrenceRules`, `hasGuests: event.hasAttendees`.
- Create `Sources/SathiCore/CalendarPage/CalendarEventForm.swift`.
  - `package struct CalendarEventForm: Equatable, Sendable { eventID: String?; title: String; start: Date; end: Date; calendarID: String?; readOnly: Bool }`.
  - `static func newEvent(at slot: Date, calendarID: String?, calendar: Calendar)`: start is rounded down to `Limits.calendarSlotMinutes`. End is start + `Limits.calendarNewEventMinutes`.
  - `func withTimes(startMinutes: Int, endMinutes: Int, calendar: Calendar) -> CalendarEventForm` (R9).
  - `var canSave: Bool`.
  - `package enum CalendarEventText { static func clean(_ raw: String) -> String? }`: line breaks become spaces, trim, cut to `Limits.blockTitleMax`, nil when empty.
- Create `Sources/SathiCore/Engine/Engine+CalendarPageEvents.swift`.
  - `package func calendarPageNewEvent(at slot: Date) -> CalendarEventForm`.
  - `package func calendarPageForm(for e: CalendarEventInfo) -> CalendarEventForm`. It is read-only when `isReadOnlyInSathi` or the calendar is not in `calendarChoices()`.
  - `package var calendarPageWritableCalendars: [CalendarChoice]`.
  - `package var calendarPageDefaultCalendarID: String?`: the last used and writable calendar, else `defaultCalendarID()`, else the first.
  - `package enum CalendarPageWriteResult: Equatable { case saved(String), failed, invalid }`.
  - `package func saveCalendarPageEvent(_ f: CalendarEventForm) -> CalendarPageWriteResult` uses `save` for a new event and `update` for an existing one.
  - `package func deleteCalendarPageEvent(_ id: String) -> Bool`.
  - `package func openEventInCalendar(_ id: String)` uses `links.open` with `static let calendarEventURLPrefix = "ical://ekevent/"`.
  - After a successful write: set `lastCalendarID`, call `markTrackerEventsStale()`, `storesChanged()`, `requestTick()`. Never create an activity.
Tests first:
`Tests/SathiCoreTests/CalendarPage/CalendarEventFormTests.swift`:
- A slot at 14:07 gives start 14:00 and end 14:30.
- A slot at 23:50 gives an end at 00:15 on the next date.
- `clean("  a\nb ")` gives "a b".
- An 80-character title is cut to 60.
- A blank title gives nil and `canSave false`.
- Times 15:00 and 15:00 give `canSave false`.
- Times 23:00 and 01:00 give an end on the next date.
- `readOnly` gives `canSave false`.
`Tests/SathiCoreTests/CalendarPage/EngineCalendarPageEventsTests.swift`:
- Create gives `saved == [draft(work, "Design", 14:00, 14:30)]`, no new activity, and `lastCalendarID "work"`.
- Edit calls `update("e1", …)`.
- Delete gives `deleted == ["e1"]`.
- With `nextSaveResult .failed` the result is `.failed` and `lastCalendarID` is unchanged.
- The default calendar: last used, then `defaultID`, then the first. A last calendar that is no longer writable is skipped.
- A repeating event gives a read-only form.
- An event with guests gives a read-only form.
- An event in a readable calendar that is not writable gives a read-only form.
- `openEventInCalendar("x")` gives `links.opened.last == URL("ical://ekevent/x")`.
- An event mapping test in `Tests/SathiUITests/CalendarMappingTests.swift`, if EKEvent is buildable there. If not, skip it.
Checks: suites, lint, build.
Commit: `feat(calendar): create, edit, delete events from the page`.

### Task C7: Tracker sync acceptance tests
Covers: C7.1–C7.6 (each with `.askFirst` and `.logAndTell`), R1.
Files:
- Change `Tests/SathiTestSupport/SpyCalendarWriter.swift`: add `package var mirrorsWrites = false`. When it is true:
  - `save` appends `CalendarEventInfo(id: "e\(saved.count)", …)` to `eventsValue`.
  - `update` changes the matching info.
  - `delete` removes it.
- Create `Tests/SathiCoreTests/CalendarPage/CalendarPageTrackerSyncTests.swift` (@Suite "Calendar page and tracker agree"). Every test is `@Test(arguments: [EventMode.askFirst, .logAndTell])`.
- Setup: `EngineHarness.tracker(at: wed(10))`, `mirrorsWrites = true`, `useEvents([], read: ["work"], mode:)`, `h.start("Spec", minutes: 300)`, `engine.calendarPageOpened()`.
- Reaction helper:
  - `.askFirst`: `h.promptKind == .eventAsk` and `engine.trackerPrompt?.eventID == id`.
  - `.logAndTell`: `h.running?.sourceEventID == id` and `h.notes.last` is `.event` of that id.
Cases:
1. `createdOnPageReactsAtItsStart`: save "Design" in "work" at 14:00. No reaction at 13:59, the reaction at 14:00.
2. `outsideEventShowsAfterChangeAndReacts`: append `meeting("x1", from: wed(14), to: wed(14,30))` and `fire()`. `calendarPage(day).blocks` has x1. Reaction at 14:00.
3. `deletedBeforeStartGivesNoReaction`: no reaction at 14:00, both through the page delete and through an outside delete with `fire()`.
4. `movedLaterReactsOnlyAtNewStart`: no reaction at 14:00, the reaction at 15:00, through the page edit and through an outside move with `fire()`.
5. `untickedCalendarShowsButNoReaction`: an event in "home" shows on the page. No reaction at its start.
6. `afterLoggingPageShowsOneBlock`:
   - `.logAndTell`: after 14:00, the blocks titled "Design" are exactly 1 and its source is `.activity`.
   - `.askFirst`: `answerEventAsk(true)`, then the same.
   - After the activity ends and is stored, still 1.
Steps: write the tests. If one fails, fix only the sync glue (C5 and C6). Never change the tracker's event rules.
Checks: `./scripts/test.sh CalendarPageTrackerSyncTests`, `./scripts/test.sh SathiCoreTests`, lint.
Commit: `test(calendar): page and tracker agree on events`.

### Task C8: UI shell: route, sidebar, Settings switch, header, access
Covers: C1.1, C1.2, C1.4, C1.5, C2.1, R8, R12.
Files:
- Change `Sources/SathiCore/Models/MainPage.swift`: add `case calendar(DayKey?)`.
- Change `Sources/SathiUI/Features/Main/MainView.swift`: `.calendar` shows `CalendarPage(day:)` when `prefs.calendarPage.isOn`, else `TodayPage()`.
- Change `Sources/SathiUI/Features/Main/MainSidebar.swift` and `SidebarRail.swift`: add the item after Activities only when on. Add the icon "calendar".
- Change `MainSidebarItem.swift`: add `var tag: String?`.
- Check `Sources/SathiUI/Windows/UIController+Main.swift` for a switch on MainPage.
- Change `Sources/SathiUI/Features/Settings/GeneralTab.swift`: add a `SettingsSection("Experimental")` with a SettingRow "Calendar page (experimental)" and a BuddySwitch bound to `$e.data.prefs.calendarPage.isOn`.
- Create `Sources/SathiUI/Features/Calendar/CalendarPage.swift`.
  - State: `range: CalendarPageRange?`, `RangeMemo`.
  - `.onAppear { e.calendarPageOpened() }`, `.onDisappear { e.calendarPageClosed() }`.
- Create `CalendarPageHeader.swift`: segment Day/Week/Month, ‹, Today, ›, the title, and the "6 AM to 6 AM" note.
- Create `CalendarAccessGate.swift`: notAsked gives "Allow calendar access" (`requestCalendarAccess`). Denied gives "Open System Settings" (`openCalendarSettings`). Reuse the copy from `TrackerAccessStatus`.
- Create `Sources/SathiCore/Formatting/Copywriter+CalendarPage.swift`: `calendarPageTitle`, `calendarExperimentalTag`, `calendarSettingLabel`, `calendarToday`, `calendarDayBoundary`, `calendarRangeTitle(_:calendar:)`.
- Create `Sources/SathiUI/Constants/UIMetrics+CalendarPage.swift`.
Tests first:
- `Tests/SathiUITests/Main/MainSidebarTests.swift`: off gives no "Calendar" text. On gives "Calendar" after "Activities" and the "Experimental" tag. A tap sets `route.page == .calendar(nil)`.
- `Tests/SathiUITests/Calendar/CalendarPageHeaderTests.swift`: the 3 segment buttons. › stays enabled on the range that holds now. Today resets. "6 AM to 6 AM" shows.
- `CalendarAccessGateTests.swift`: notAsked shows "Allow calendar access". Denied shows "Open System Settings" and a tap gives `links.opened == [calendarPrivacyURL]`.
- `GeneralTabTests`: the switch exists and is off by default.
- `MainViewTests`: `.calendar` when off shows Today.
- `Tests/SathiCoreTests/EngineMainPageTests.swift`: `openMain(.calendar(nil))` gives `presenter.calls` `.showMain(.calendar(nil))`.
Checks: `./scripts/test.sh SathiUITests`, lint, build.
Commit: `feat(calendar): calendar page shell, sidebar item, settings switch`.

### Task C9: UI grid, blocks, now line, Month
Covers: C2.2–C2.4, C2.6–C2.10, C3.4, C9.1.
Files:
- Create in `Sources/SathiUI/Features/Calendar/`:
  - `CalendarGridMath.swift`: `y(for:in:hourHeight:)`, `height(_:)`, `slotStart(y:in:)`.
  - `CalendarTimeGrid.swift`: 24 rows, ScrollViewReader, `initialScrollRow`.
  - `CalendarDayColumn.swift`: places `CalendarPlacedBlock` by lane.
  - `CalendarBlockView.swift`: static `showsText(height:)` and `showsTimeRange(height:)`.
  - `CalendarAllDayRow.swift`.
  - `CalendarNowLine.swift`: uses `e.now`, only in the today column, no TimelineView.
  - `CalendarMonthGrid.swift` and `CalendarMonthCellView.swift`: a click opens the Day range of that date.
- Add metrics to `UIMetrics+CalendarPage.swift`: `calendarHourHeight`, `calendarBlockMinHeight`, `calendarTimeRangeMinHeight`, `calendarAllDayHeight`, `calendarNowLineWidth`, `calendarMonthCellMinHeight`.
Tests first:
- `Tests/SathiUITests/Calendar/CalendarGridMathTests.swift`: 06:00 gives y 0. 07:30 gives 1.5 × hourHeight. 05:00 of the next date gives 23 × hourHeight. A slot at y = 2.3 h gives 08:15 (rounded down 15).
- `CalendarBlockViewTests.swift`: below the minimum height there is no text. A tall block shows the title and the range. An event block uses the outline. Away uses grey.
- `CalendarMonthGridTests.swift`: "+2 more". A tap on a date sets the Day range. The today highlight.
Checks: `./scripts/test.sh SathiUITests`, lint, build, `./build.sh --install` then `./scripts/perf.sh` (C9.3).
Commit: `feat(calendar): time grid, blocks, month grid`.

### Task C10: New event popover, shown calendars, stats, activity edit
Covers: C4.1, C6.1–C6.8, C6.11, C8.2.
Files:
- Create in `Sources/SathiUI/Features/Calendar/`:
  - `CalendarEventPopover.swift`: title field (QuickTextLimit 60), 2 TimeMenu, square calendar boxes, Save (disabled when `!canSave`), Cancel, Delete (edit only), an error line. Read-only shows the values and "Open in Calendar" only.
  - `CalendarEventPopover+Outcome.swift`: `static func closes(after: CalendarPageWriteResult) -> Bool`.
  - `CalendarShownList.swift`: check boxes grouped by account.
  - `CalendarStatsPanel.swift` and `CalendarStatsLine.swift`.
- `CalendarPage` opens `ActivityEditPanel` for an activity block with `e.activityDay(DayKey(a.start, calendar:))` and the same `ActivityDayActions` as `ActivitiesPage`.
Tests first: `Tests/SathiUITests/Calendar/`.
- `CalendarEventPopoverTests`: fields "Title", start and end TimeMenu, calendar boxes, Save off on a blank title, no Delete for new, Delete for edit, read-only shows "Open in Calendar" and no Save, `closes(after: .failed) == false`, `closes(after: .saved) == true`.
- `CalendarShownListTests`: a tap on "Home" gives `hiddenCalendarIDs == ["home"]`.
- `CalendarStatsPanelTests`: tracked, planned, categories.
Checks: `./scripts/test.sh SathiUITests`, lint, build, perf.
Commit: `feat(calendar): event popover, shown calendars, stats panel`.

## Track 2: Manual merge (worktree branch `feat/manual-merge`)

### Task M1: Rules, constants, merge check
Covers: M1.1–M1.5, M3.1 (text), M3.3, R4, R5.
Files:
- Change `.claude/rules/business-logic.md`: add rule 11f "Manual merge (phase 21)" after 11e (M1–M4, R3–R5).
- Create `Sources/SathiCore/Constants/Limits+ManualMerge.swift` (`manualMergeMinRows = 2`).
- Create `Sources/SathiCore/Constants/Timing+ManualMerge.swift` (`mergeUndoShow: TimeInterval = 30`).
- Create `Sources/SathiCore/Tracker/Rules/ManualMerge.swift`.
  - `package enum ManualMergeBlock: Equatable, Sendable { case tooFew, notStored, differentDays, eventRow, buddyRow, timeBlockRow, namedAway, rowBetween }`.
  - `package struct ManualMergePlan: Equatable, Sendable { merged: Activity; rows: [Activity]; removedAway: [Activity]; keptEventRow: Activity?; droppedEventRows: [Activity] }`.
  - `package enum ManualMergeCheck: Equatable { case ok(ManualMergePlan), blocked(ManualMergeBlock) }`.
  - `static func check(_ ids: Set<ActivityID>, dayRows: [Activity], calendar: Calendar) -> ManualMergeCheck`.
- Create `Sources/SathiCore/Formatting/Copywriter+ManualMerge.swift`: `mergeButton`, `mergeBlocked(_:)` (one line per case), `mergePreview(count:start:end:calendar:)` gives "{n} rows become 1, {start} to {end}", `mergeCalendarFailed` ("The calendar did not change, so Sathi did not merge."), `mergeUndo`, `mergeUndoCalendarFailed`.
Tests first: `Tests/SathiCoreTests/Tracker/Engine/ManualMergeTests.swift`, parameterized:
- Allowed:
  - 2 work rows with a gap: merged = first id, text and category, first start, last end.
  - Different texts can merge.
  - An unnamed Away between is removed.
  - Empty time between is fine.
  - An unnamed Away inside the selection is removed.
- Blocked:
  - 1 row gives `tooFew`.
  - A running or unknown id gives `notStored`.
  - Rows on 2 dates give `differentDays`.
  - A selected `.event` row, or a work row with `sourceEventID`, gives `eventRow`.
  - `.buddy` gives `buddyRow`. `.timeBlock` gives `timeBlockRow`.
  - An Away with `awayPlace` or `awayPlaceName` gives `namedAway`.
  - An unselected work row between gives `rowBetween`.
- Event bookkeeping: `keptEventRow` is the first row with an event. The rows behind it are in `droppedEventRows`. With no events both are empty.
- Copy: the preview line text.
- `ActivityMergeTests` stays unchanged (M3.3).
Checks: `./scripts/test.sh ManualMergeTests`, `./scripts/test.sh ActivityMergeTests`, lint, build.
Commit: `feat(merge): manual merge rules and check`.

### Task M2: Engine merge and storage
Covers: M1.5, M2.4, M3.4.
Files:
- Create `Sources/SathiCore/Engine/Engine+ManualMerge.swift`.
  - `package func mergeCheck(_ ids: Set<ActivityID>) -> ManualMergeCheck`.
  - `package enum ManualMergeResult: Equatable { case merged(ActivityID), blocked(ManualMergeBlock), calendarFailed }`.
  - `@discardableResult package func mergeActivities(_ ids: Set<ActivityID>) -> ManualMergeResult`.
  - `func replaceDayRows(removing: Set<ActivityID>, with row: Activity)`: one `activityStore.save` of the month, then `storesChanged()`.
Tests first: `Tests/SathiCoreTests/Tracker/Engine/EngineManualMergeTests.swift`.
- 3 rows plus 1 unnamed Away merge to 1 stored row with the first id, 10:00 to 11:30.
- No calendar calls when no row has an event (`saved`, `updated`, `deleted` all empty).
- A blocked merge returns `.blocked` and `h.saved` is unchanged.
- The running activity is not mergeable.
- After a merge, a tracker answer with the same text 30 s after the merged end still auto-merges per rule 11c (M3.3).
Checks: suite, lint, build.
Commit: `feat(merge): engine manual merge`.

### Task M3: Calendar steps and rollback
Covers: M2.1–M2.3, R3, R4.
Files:
- Create `Sources/SathiCore/Engine/Engine+ManualMergeCalendar.swift`: `func mergeCalendarSteps(_ plan: ManualMergePlan) -> MergeCalendarSteps?`.
  1. `update(eventID:, draft: merged.text, merged.start, merged.end, keptEventRow.calendarID)`. `.failed` or `.calendarMissing` stops with nothing changed.
  2. Delete the events of the dropped rows one by one.
  3. When a delete fails: save each event deleted so far again (with its row's own text and times, new id set on that row), move the kept event back to its row's old times, and return nil, so the result is `.calendarFailed`.
- `mergeActivities` calls it before `replaceDayRows`.
Tests first: `Tests/SathiCoreTests/Tracker/Engine/EngineManualMergeCalendarTests.swift`.
- Rows A(e1), B(e2), C(no event): `updated == [("e1", 10:00–11:30)]`, then `deleted == ["e2"]`, and the merged row has e1.
- Only B has an event: the kept event is e2 and its calendar is B's.
- Update order: with `nextUpdateResult = .failed`, `deleted` is empty and the result is `.calendarFailed`.
- Delete failure: rows A(e1), B(e2), C(e3) with `deleteResults["e3"] = false` give `deleted == ["e2","e3"]`. `saved` holds B's draft again. `updated.count == 2` and the last one has A's old times. The rows are unchanged except B gets the new event id. The copy says "The calendar did not change, so Sathi did not merge."
- No row with an event gives no calendar call (M2.4).
Checks: suite, lint, build.
Commit: `feat(merge): calendar update then delete with rollback`.

### Task M4: Undo
Covers: M3.2.
Files:
- Change `Sources/SathiCore/Engine/Engine.swift`: add `@Published package internal(set) var mergeUndo: ManualMergeUndo?`.
- Create `Sources/SathiCore/Tracker/ManualMergeUndo.swift`: `package struct ManualMergeUndo: Equatable { merged: Activity; before: [Activity]; keptEvent: (row: Activity)?; deletedEventRows: [Activity]; until: Date }`.
- Create `Sources/SathiCore/Engine/Engine+ManualMergeUndo.swift`.
  - `package enum ManualMergeUndoResult: Equatable { case restored, restoredCalendarFailed, gone }`.
  - `package func undoMerge() -> ManualMergeUndoResult`: the rows always come back. The calendar steps are best effort. Events that are made again set new ids.
  - `func clearMergeUndo()`, `func expireMergeUndo()`, `var mergeDeadlines: [Date]`.
- Change `Sources/SathiCore/Engine/Engine+Loop.swift`: add `expireMergeUndo()` in `tick()` and `+ mergeDeadlines` in `upcomingDeadlines()`.
- Change `Engine+TrackerReportAPI.swift`: `editActivity`, `addPastActivity` and `deleteActivity` call `clearMergeUndo()` first.
Tests first: `Tests/SathiCoreTests/Tracker/Engine/EngineManualMergeUndoTests.swift`.
- Undo restores the ids, times, texts and categories of every row, including the removed Away rows.
- Kept e1 moves back to the old times. A deleted e2 is saved again and B gets the new id.
- A failed save on undo gives `.restoredCalendarFailed` and the rows are still back.
- After 30 s `mergeUndo == nil`, and `nextTickDelay() <= 30` right after a merge.
- An edit, add or delete clears it.
- A merged row that changed after the merge (auto-merge) gives `.gone`.
Checks: suite, `./scripts/test.sh SathiCoreTests`, lint, build.
Commit: `feat(merge): undo for manual merge`.

### Task M5: Activities Day view selection and Merge bar
Covers: M1.1, M1.3 (button off with reason), M3.1, M3.2 UI, M4.1.
Files:
- Change `Sources/SathiUI/Features/Reports/Activities/ActivityActions.swift`: add `mergeCheck`, `merge`, `undoMerge` to `ActivityDayActions`.
- Change `ActivityDayView.swift`: add `@State var selected: Set<ActivityID>`.
- Change `ActivityTimelineList.swift`: add `selected` and `onToggle`.
- Create `ActivitySelectBox.swift`: a square box. Not shown for the running row.
- Create `ActivityMergeBar.swift`: preview or reason line, Merge button, error line, Undo. Add `static func state(_ check: ManualMergeCheck, calendar:) -> (enabled: Bool, line: String)`.
- Change `ActivitiesPage.swift`: wire the actions.
- Create `Sources/SathiUI/Constants/UIMetrics+ManualMerge.swift`.
Tests first: `Tests/SathiUITests/Tracker/Reports/ActivityMergeBarTests.swift`.
- `state(.blocked(.namedAway))` gives `enabled false` and the line for named Away.
- `state(.ok)` gives "3 rows become 1, 10:00 AM to 11:30 AM".
- The Merge button calls `actions.merge`.
- Undo shows when `mergeUndo != nil`.
- The error line shows after `.calendarFailed`.
- `ActivityTimelineList` shows a select box per stored row and none for the running row.
Checks: `./scripts/test.sh SathiUITests`, lint, build, perf.
Commit: `feat(merge): select and merge on the Activities day view`.

## Integration (on `feat/calendar-page` after both tracks merge)

### Task I1: Merge on the Calendar page Day view
Covers: M4.2, R10.
Files:
- Change `CalendarPage.swift` and `CalendarBlockView.swift`: in the Day view only, ⌘-click on an activity block toggles selection and shows a highlight.
- Show `ActivityMergeBar` (same `mergeCheck`, `mergeActivities`, `undoMerge`).
- Add the hint line `Copywriter.calendarMergeHint`.
- Clear the selection on a range change.
Tests first: `Tests/SathiUITests/Calendar/CalendarMergeTests.swift`.
- The bar shows when 2 or more blocks are selected.
- Blocks across midnight give the `differentDays` line.
- Merge calls the engine.
- Week and Month have no selection.
Checks: `./scripts/test.sh`, lint, build.
Commit: `feat(calendar): merge on the calendar day view`.

### Task I2: Cross-track acceptance, docs, perf
Covers: spec "Required tests", C9.3.
Tests: `Tests/SathiCoreTests/CalendarPage/CalendarPageMergeTests.swift`.
- After merging A(e1) and B(e2), `calendarPage(day)` has 1 activity block and no outline for e1 or e2.
- Undo shows 2 blocks again and no outline for the events made again (their ids are on the rows).
Docs:
- CLAUDE.md module map:
  - SathiCore `CalendarPage/` (CalendarPagePrefs, CalendarPageDay, CalendarPageRange, CalendarBlock, CalendarBlockBuilder, CalendarDisplayJoin, CalendarBlockLayout, CalendarPageStats, CalendarMonthCell, CalendarEventForm).
  - Ports `CalendarChangeSource`.
  - `Rules/ManualMerge`.
  - Engine `+CalendarPage`, `+CalendarPageCalendars`, `+CalendarPageSync`, `+CalendarPageEvents`, `+ManualMerge`, `+ManualMergeCalendar`, `+ManualMergeUndo`.
  - SathiUI `Features/Calendar/`.
  - Platform `EventKitCalendarChangeSource`.
  - TestSupport `FakeCalendarChangeSource`.
- `docs/ROADMAP.md`: a "Phase 21: Calendar page and manual merge" entry.
- `/sathi-website` for Merge.
Checks:
- `./scripts/test.sh` (report the real counts).
- `./scripts/lint.sh`.
- `swift build -c release`.
- `./build.sh --install` and `./scripts/perf.sh`. The user runs `./scripts/perf.sh --windows`.
Commit: `docs(phase-21): module map, roadmap, acceptance tests`.

### Critical Files for Implementation
- /Users/cefalo_1/Documents/Projects/Sathi-calendar/Sources/SathiCore/Engine/Engine+TrackerCalendarRead.swift
- /Users/cefalo_1/Documents/Projects/Sathi-calendar/Sources/SathiCore/Ports/CalendarWriter.swift
- /Users/cefalo_1/Documents/Projects/Sathi-calendar/Sources/SathiCore/Engine/Engine+TrackerTidy.swift
- /Users/cefalo_1/Documents/Projects/Sathi-calendar/Tests/SathiTestSupport/SpyCalendarWriter.swift
- /Users/cefalo_1/Documents/Projects/Sathi-calendar/Sources/SathiUI/Features/Reports/Activities/ActivityDayView.swift
