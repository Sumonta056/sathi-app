# Phase 17 wave 0 contracts

What wave 1 and wave 2 tracks build against. Source of truth is the code; this file is the map. Frozen after wave 0 (only a contract fix changes it).

## Public signatures

### Engine+TrackerAPI (T1 fills)
```swift
package var runningActivity: RunningActivity? { data.live.tracker.running }
package var trackerPrompt: PromptState? { data.live.tracker.prompt }
package var trackerQuietUntil: Date? { data.live.tracker.running?.quietUntil }
package var recentActivities: [RecentActivity]                  // stub []
package func trackerPromptState(_ kind: PromptKind) -> TrackerPromptState?   // stub nil
package func trackerEndOfDayState() -> TrackerEndOfDayState?    // stub nil
package func startActivity(_ draft: ActivityDraft, switchAt: Date? = nil)    // A/B Enter, recent chip; switchAt = Started row pick
package func skipTrackerPrompt(switchAt: Date? = nil)           // Skip in A (after Done: ends old at switchAt) and C
package func stillOnIt(minutes: Int? = nil)                     // C on time: nil = askEvery, 5, 30
package func stillOnItLate()                                    // late C "Still on it"
package func doneActivity()                                     // C Done, menu Done
package func continueActivity(switchAt: Date? = nil)            // A "Continue {text}" after a buddy session
package func backToLastActivity()                               // D Enter
package func iWasHere()                                         // D, idle Away only
package func setAwayPlace(_ place: AwayPlace)                   // D chips
package func closeTrackerPrompt()                               // Esc in B or D
package func openTrackerPanel()                                 // menu "Log activity" → B
package func trackerShortcutPressed()                           // hotkey → B, ends quiet time
package func endQuietTime()                                     // menu
package func presenceChanged(_ event: PresenceEvent)
package func closeTrackerEndOfDay()
package func openActivityReport(_ day: DayKey)
```
### Engine+TrackerReportAPI (T1 fills)
```swift
package var activityReportDay: DayKey? { trackerRuntime.reportDay }
package func activityDay(_ day: DayKey) -> ActivityDay          // stub: empty day, zero-length hours
package func activityDays(in month: MonthKey) -> [ActivityDay]  // stub []
package func daysWithActivities(in month: MonthKey) -> Set<DayKey>  // stub []
@discardableResult package func editActivity(_ id: ActivityID, _ edit: ActivityEdit) -> ActivityEditResult  // stub .notFound
@discardableResult package func addPastActivity(_ edit: ActivityEdit) -> ActivityEditResult                // stub .notFound
package func deleteActivity(_ id: ActivityID)
```
### Engine+TrackerCategories (real)
```swift
package var activityCategories: [ActivityCategory]
@discardableResult package func addActivityCategory(_ name: String, colorHex: UInt32) -> Bool
@discardableResult package func renameActivityCategory(_ old: String, to name: String) -> Bool
package func deleteActivityCategory(_ name: String)
package func setActivityCategoryColor(_ name: String, colorHex: UInt32)
```
### Engine+TrackerHooks (T1 fills, internal)
```swift
var trackerDeadlines: [Date]            // stub []
var trackerHoldsBuddyPopups: Bool       // stub false (quiet time, rule 58)
func tickTracker(); func restoreTracker(); func stopTracker()
func trackerPrefsChanged(from old: TrackerPrefs)
func trackerBreakChanged(from old: Date?)
func trackerSessionStarted(_ id: HabitID); func trackerSessionEnded(_ id: HabitID)
func trackerBlockStarted(); func trackerBlockSaved(_ block: TimeBlock, end: Date)
```
### Engine+TrackerCalendar (C fills)
```swift
package func readableCalendarChoices() -> [CalendarChoice]
@discardableResult package func saveActivityToCalendar(_ id: ActivityID) -> Bool   // "Not in calendar" → Save
package func trackerNoteState() -> TrackerNoteState?
package func undoEventNote(); package func notAttendingEvent(_ eventID: String)
package func setEventCategory(_ category: String); package func answerEventAsk(_ yes: Bool)
package func switchToOverlappingEvent()
var trackerEventDeadlines: [Date]                                     // internal; T1 adds it to trackerDeadlines
func tickTrackerEvents()                                               // T1 calls from tickTracker
func unloggedRunningEvent() -> CalendarEventInfo?                      // first chip (rule 47)
func savingToCalendar(_ activity: Activity) -> Activity               // on end; returns with eventID
func calendarActivityEdited(from old: Activity, to new: Activity) -> Activity
func calendarActivityDeleted(_ activity: Activity)
func logEventsWhileAway(from start: Date, to end: Date) -> [Activity]
```

### Ports
```swift
package protocol ActivityStore: AnyObject, Sendable {
    func month(_ key: MonthKey) -> ActivityMonth
    func save(_ month: ActivityMonth)
    func savedMonths() -> [MonthKey]
    @discardableResult func flush() -> Bool
}
extension ActivityStore { package func allActivities() -> [Activity] }

package enum PresenceEvent: Equatable, Sendable { case locked, unlocked, sleep, wake }
@MainActor package protocol PresenceMonitor: AnyObject {
    func start(_ onEvent: @escaping @MainActor (PresenceEvent) -> Void)
    func stop()
    func secondsSinceLastInput() -> TimeInterval
}

@MainActor package protocol HotkeyRegistrar: AnyObject {
    @discardableResult func register(_ shortcut: KeyShortcut, onPress: @escaping @MainActor () -> Void) -> Bool
    func unregister()
}

CalendarWriter additions:
    @discardableResult func delete(eventID: String) -> Bool
    func readableCalendars() -> [CalendarChoice]
    func events(from start: Date, to end: Date, calendarIDs: [String]) -> [CalendarEventInfo]
package struct CalendarEventInfo { id, title, start, end, calendarID, isAllDay = false, declined = false }

ReminderPresenter additions:
    func showTrackerPrompt(_ kind: PromptKind)
    func closeTrackerPrompt(_ kind: PromptKind)
    func showTrackerNote(_ note: TrackerNote)
    func closeTrackerNote()
    func showTrackerEndOfDay()
    func closeTrackerEndOfDay()
```

### TrackerPromptState (T4 views read only this)
```swift
package struct TrackerPromptState {
    var kind: PromptKind; var shownAt: Date; var now: Date
    var draft: ActivityDraft                 // prefilled: default category, usual length, ask 0, calendar if on by default
    var running: RunningActivity?            // C: text, category, start, expectedLength
    var lastActivity: ActivityDraft?         // D "Back to {text}"
    var resume: ActivityDraft?               // A "Continue {text}" (rule 55)
    var recents: [RecentActivity] = []       // newest first; A shows 3, B shows 4
    var categories: [ActivityCategory] = []
    var calendars: [CalendarChoice] = []     // writable, grouped by .account in the view
    var switchTimes: [Date] = []             // Started row; empty = no row; last = now; > Limits.switchChipsBeforeGrid → grid
    var waitedMinutes: Int?                  // late C
    var away: AwaySpan?                      // D eyebrow, fromIdle → "I was here"
    var loggedWhileAway: [Activity] = []     // D "While you were away"
    var runningEvent: CalendarEventInfo?     // first chip in A and B
    var event: CalendarEventInfo?            // eventAsk prompt
    var calendar: Calendar = .current
    var actions = TrackerPromptActions()
    init(kind:shownAt:now:draft:)
    var showsSwitchRow: Bool; var isLate: Bool
}
package struct TrackerPromptActions {        // all @MainActor, all default to no-op
    start(ActivityDraft, Date?), skip(Date?), stillOn(Int?), stillOnLate(), done(), continueLast(Date?),
    backToLast(), iWasHere(), pickPlace(AwayPlace), notAttending(String), answerEvent(Bool),
    pickEventCategory(String), close()
}
```
PromptKind: `whatNow` (A), `center` (B), `stillOnIt` (C), `welcomeBack` (D), `eventAsk` (ask-first). `isCorner` is true for A, C, eventAsk. Note F is `TrackerNote` (`.event`, `.alsoNow`), not a prompt.

### Stored shapes
- `TrackerPrefs`: every spec field with spec defaults; plus computed `days: HabitDays`, `sortedWeekdays`, `defaultCategory` (first category). Lenient: each bad field → its default; hours must be 0…1440 and a multiple of 5; askEvery and idle must be chips; a bad category item is dropped; a shortcut with no modifiers → default. Weekdays and daysOff encode sorted.
- `TrackerLiveState`: `running`, `prompt`, `awaySince`, `awayCause`, `awayPlan: AwayPlan?` (phase 20, planned place of a chosen Away), `lastInput`, `lastEndOfDay: DayKey?`, `lastActivity: ActivityDraft?`, `beforeSession: ActivityDraft?`. Every field lenient; dates rounded on decode.
- `RunningActivity`: spec fields plus `kind`, `lastAnswer` (for the Started row) and `confirmedUntil` (rule 22); init sets lastAnswer = start, confirmedUntil = askAt. `activity(until:)` builds the saved item.
- `Activity`: spec item fields. `id`, `kind`, `start`, `end` strict (an item without them fails, so T2 keeps it as raw JSON); the rest lenient; an unknown `awayPlace` loads nil.

### Constants added
Limits: activityTextMax 80, activityLengths [15,30,60], askOffsets [0,5,15], recentMax 5, recentInCorner 3, recentInCenter 4, trackerAskChips [10,15,20,30,60], idleChips [10,20,30,60], categoryMax 16, categoryNameMax 24, trackerStartMinutes 540, trackerEndMinutes 1080, trackerAskEveryDefault 15, trackerUsualLengthDefault 30, idleDefault 30, switchStepMinutes 5, switchChipsBeforeGrid 4, monthlyTopTexts 3, spaceKeyCode 49, spaceKeyName "Space".
Timing: activityMinimum 60 s, lateAnswer 5 min, eventNoteShow 1 min, endOfDayAnimation 1.5 s.
StorageKeys: activitiesFolder "activities", exportActivitiesPrefix "Sathi-activities-". SoundName: `trackerPrompt = .tink`.

## Hook points in shared engine files

All call empty stubs in `Engine+TrackerHooks.swift` (T1) until filled.

| Where | Call |
|---|---|
| `Engine.swift` `data.didSet` | `trackerPrefsChanged(from: oldValue.prefs.tracker)` when tracker prefs change |
| `Engine.swift` `pausedUntil.didSet` | `trackerBreakChanged(from: oldValue)` (break start, end, expiry) |
| `Engine+Loop.swift` `start()` / `stop()` | `restoreTracker()` / `stopTracker()` |
| `Engine+Loop.swift` `tick()` | `tickTracker()` after `showDaySummaryIfDue()`; `presentDueHabits()` skipped while `trackerHoldsBuddyPopups` |
| `Engine+Loop.swift` `upcomingDeadlines()` | adds `trackerDeadlines` |
| `Engine+Session.swift` `startSession` | `trackerSessionStarted(id)` after `sessionStarted(id)` |
| `Engine+Actions.swift` `close(_:)`, `.session` case | `trackerSessionEnded(id)` (finish and stop), before `activities[id] = nil` |
| `Engine+TimeBlock.swift` `startBlock` | `trackerBlockStarted()` |
| `Engine+TimeBlockCalendar.swift` `finish` (success), `saveWaitingBlock` (success) | `trackerBlockSaved(b, end:)` |

## Extra stored fields (beyond the spec Storage list)

- `RunningActivity`: `kind`, `lastAnswer` (Started row, rule 13a), `confirmedUntil` (rule 22), `sourceEventID`.
- `PromptState`: `switchFrom` (Started row), `resume` (Continue, rule 55), `eventID` (ask-first prompt).
- `TrackerLiveState`: `awayCause` (I was here only after idle, rule 18), `lastActivity` (D "Back to"), `beforeSession` (Continue after a buddy session).

All optional or defaulted; old files load (`Tests/SathiCoreTests/Tracker/Contracts/`).

## Decisions

1. **Name clash:** the engine already had `enum Activity` (habit bubble/lock/session). The spec name `Activity` is used for the tracker item; the old enum is now `HabitActivity` (2 lines changed, `Engine.activities` keeps its name).
2. **Stubs in owned files:** like `Engine+TrackerAPI` for T1, the stubs that other tracks fill live in files whose names match that track's glob: `Engine+TrackerCalendar.swift` (C), `EventKitCalendarReader.swift` (T3), `UIController+Tracker.swift` (I). No protocol default implementations, so a missing method is a compile error, not a silent no-op.
3. **Per-track runtime structs:** extensions cannot add stored properties, so `Engine` holds `trackerRuntime: TrackerRuntime` (defined in T1's `Engine+TrackerRuntime.swift`) and `trackerCalendarRuntime: TrackerCalendarRuntime` (C's file). Each track adds fields there with defaults, with no edit to `Engine.swift`.
4. **Hooks in shared engine files now:** T1 cannot edit `Engine+Loop`, `+Session`, `+Actions`, `+TimeBlock*`, so wave 0 put every call there (tick, deadlines, quiet hold of buddy popups, restore/stop, prefs change, break via `pausedUntil.didSet`, session start/end, block start/saved). All are empty stubs, so nothing changes.
5. **Extra stored fields beyond the spec list** (needed for restart, rule 22, 13a, 18, 55): `RunningActivity.kind/lastAnswer/confirmedUntil/sourceEventID`, `PromptState.switchFrom/resume/eventID`, `TrackerLiveState.awayCause/lastActivity/beforeSession`. All optional or defaulted, so old files load.
6. **Default category** for a new draft = the first category in the list (design shows Coding). Computed (`TrackerPrefs.defaultCategory`), not stored.
7. **ActivityLength** is a new type (same shape as `TimeBlockLength`), so it does not tie the tracker to time blocks, which ADR 0001 removes later.
8. **Port defaults:** `NoActivityStore`, `NoPresenceMonitor`, `NoHotkeyRegistrar` are default init params, so `AppEnvironment` is unchanged and the app behaves exactly as before. Track I passes the real ones.
9. **ActivityStore** is month-based (spec "load and save a month"). Unknown items and unknown fields are T2's job inside `FileActivityStore` (keep raw JSON per month and per id; merge on save). `ActivityMonth` holds only decoded items.
10. **Backup now:** `JSONExporter` and `ExportJob` are shared files T2 cannot edit, so wave 0 added the `activities` list to the backup and the store to `ExportJob` (tested). T2 only needs to test it with `FileActivityStore`.
11. **CalendarWriter.readableCalendars()** added (not in the spec list): the settings row "Read these calendars" needs all calendars, and `calendars()` returns only writable ones.
12. **Category editing is real, not a stub** (pure `ActivityCategoryList` + 4 engine methods, tested), because G47 needs a unit test and T6 owns only UI files.
13. **Buddy category colors** use the Night buddy accents (reading F2A64A, meditation A99CF5, gym CDEF5A). The design page uses C9B8FF for Meditation; the spec says "the buddy color". Change in `ActivityCategory.buddy` if the design wins.
14. **Prompt sound** = existing `.tink` via `SoundName.trackerPrompt` (no new sound file).
15. **Copy for formats:** the standup and monthly line formats exist as Copywriter functions (tested); the order and grouping (rules 35, 36) are T5's builder work.
16. Plan said wave 0 runs on `feat/activity-tracker` directly; the brief (and the controller) said a worktree branch `feat/tracker-w0-contracts`. I followed the brief.

