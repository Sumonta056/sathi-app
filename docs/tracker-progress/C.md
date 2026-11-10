# C: Calendar engine

Status: done, ready to merge

Plan and goals: `docs/specs/phase-17-plan.md` (section C). Contracts: [`CONTRACTS.md`](CONTRACTS.md).

## Notes from wave 0

- Fill: `Engine+TrackerCalendar.swift` (public actions + internal hooks) and `Engine+TrackerCalendarRuntime.swift` (add fields with defaults).
- Runtime changes do not refresh the UI; call `objectWillChange.send()` when a view must update.

## Plan

Files (all new or C stubs, each under 200 lines):

| File | Job |
|---|---|
| `Tracker/Calendar/EventRules.swift` | Pure: usable events (timed, not declined, not Sathi-written, start inside tracker hours on a tracker day), the dedupe key (id + start, recurring events share an id), first-stays order |
| `Tracker/Calendar/EventCategoryRule.swift` | Pure: category order (title pick, calendar category if it still exists, calendar name) and the new calendar-name category |
| `Tracker/Calendar/SpanCut.swift` | Pure: cut event spans out of an Away span |
| `Engine+TrackerCalendarRuntime.swift` | Runtime: day cache, read time, read key, checked-until, seen and dismissed keys, note, note end, undo info |
| `Engine+TrackerCalendarWrite.swift` | Write side: save on end (rule 29), Save button (31), edit update and delete (30) |
| `Engine+TrackerCalendarRead.swift` | Read side: read 1 day only when due (first tick, new day, ticked list change, an event start, an ask time), usable events, deadlines, first chip |
| `Engine+TrackerCalendarTick.swift` | Event start: log and tell (switch + note F), ask first (eventAsk prompt), overlap note, event end opens A with the Started row |
| `Engine+TrackerCalendarAway.swift` | Mac away at an event start: log the event, cut the Away items, D rows |
| `Engine+TrackerCalendar.swift` | Public actions: Undo, Not attending, category pick, ask answer, Switch, note state, readable calendars |

Key choices:
- Sathi reads events only at a due time, never on a timer: `trackerEventDeadlines` = the next usable event start and the note end. Each read covers 1 day.
- An event start is handled once (`checkedUntil` moves on every tick). After a restart, past starts are not handled again; a running event is then offered as the first chip.
- Events are skipped while a time block or a buddy session runs (no tracker activity runs then). While Away they are logged on return.
- At the event end the event activity gets A with the Started row from the event end (rule 51), so it ends at the picked time, never by itself.
- Time block event IDs are not stored after the block, so a time block event is found by the stored time block activity (same title and start).

## Progress

Tests: `Tests/SathiCoreTests/Tracker/Calendar/` (58 tests, 7 suites). All 1706 core + 898 UI tests pass, lint OK, `swift build` has no new warning.

| Goal | Test |
|---|---|
| G26 | `EngineTrackerCalendarWriteTests.addToCalendarIsOffByDefaultAndTheMenuListsWritableCalendarsByAccount` (the menu view is T4) |
| G27 | `anActivityWithACalendarSavesOneEventWithItsRealStartAndEndAndKeepsTheID`, `anActivityWithoutACalendarWritesNoEvent` (1 real Gmail event: user) |
| G28 | `aReportEditUpdatesTheEvent`, `aMissingEventChangesOnlyTheLog` (2 args), `aDeleteDeletesTheEvent`, `aMissingEventOnDeleteStillDeletesTheActivity` |
| G29 | `aCalendarFailureKeepsTheActivityWithoutAnEventAndNeverBlocks` (2 args), `saveRetriesTheEventForANotInCalendarRow` |
| G30 | `EngineTrackerCalendarReadTests.readingIsOffByDefaultAndNothingIsRead`, `onlyTheTickedCalendarsAreReadAndEachReadIsOneDayAtMost` |
| G31 | `allDayDeclinedAndSathiWrittenEventsAreSkippedAndFreeEventsCount`, `eventsOutsideTrackerHoursOrOnANonTrackerDayAreSkipped` |
| G32 | `EngineTrackerEventTests.logAndTellSwitchesAtTheEventStartAndShowsTheNoteForOneMinute`, `noStillOnItAsksBeforeTheEventEndAndTheEndOpensWhatNowWithTheStartedRow`, `theEventWinsOverAStillOnItAtTheSameMoment`, `undo…`, `notAttending…`, `quietTimeHidesTheNoteButTheEventIsStillLogged` |
| G33 | `askFirstShowsThePromptAndTheOldActivityGoesOn`, `askFirstYesLogsFromTheEventStartAlsoWhenLate`, `askFirstNoKeepsTheOldActivityAndNeverAsksAgain`, `askFirstCategoryPickIsUsedByYes` |
| G34 | `EngineTrackerEventAwayTests` (5 tests: logged with no question, Away cut at the event, return mid-event, Not attending row, overlap, reading off) |
| G35 (engine part) | `EngineTrackerEventOverlapTests.aRunningEventThatIsNotLoggedIsTheFirstChipInAAndB` |
| G36 | `categoryIsTheTitlePickThenTheCalendarCategoryThenTheCalendarName`, `aDeletedCalendarCategoryFallsBackToTheCalendarName`, `aCategoryPickInTheNoteChangesTheActivityAndIsKeptForThatTitle`, `EventRulesTests` |
| G37 | `anActivityFromAnEventNeverWritesAnEvent`, `noEventIsLoggedTwoTimes`, `aRestartDuringALoggedEventDoesNotLogItAgain`, `aRecurringEventWithTheSameIDIsLoggedAtEachStart` |
| G38 | `whenTwoEventsOverlapTheFirstStaysAndANoteOffersSwitch`, `notAttendingTheSecondEventKeepsTheFirst`, `overlappingEventsWhileAwayKeepTheFirst` |
| G54 (events) | `theNextEventStartIsATickDeadline`, `ticksWithNoDueTimeDoNotReadAgain`, `anEventAddedLaterIsSeenAtTheNextAskTime` |
| P5 | Log and tell needs no typing; manual check by the user |

Decisions (need a human eye):
- Events are read again (1 day) on the first tick, a new day, a change of ticked calendars, and when an event start, an activity start, an ask time, a What now time, or the hours start has passed since the last read. No timer.
- Turning reading on in the middle of an event does not log it; it is offered as the first chip. The same after a restart.
- Events are skipped while a time block or a buddy session runs, and during a break they are logged on return (break is Away).
- Ask first during quiet time: the prompt waits until quiet time ends (T1 holds every corner prompt while busy). Log and tell logs during quiet time with no note.
- Ask first does not replace an open B, D, or an A after Done; the event is then only the first chip.
- An event activity ends only by an answer: at its end A opens with the Started row from the event end (rule 51); Esc or Skip end it at the event end.
- Not attending on note F opens A with the Started row from the event start (no Continue button). Not attending on a D row turns the row back into Away with the Away place.
- "I was here" after an idle Away keeps an event logged while away once: the event that the Away cut is not restored as running.
- An ask-first prompt lost to a lock (or replaced by D, B, a session) asks again later the same day until it is answered. A late Yes trims the old activity to the event start and cuts the Away over the event.
- A break that ends while the Mac is still locked or asleep stores an event to its own end (no running event); the later Away is cut around it.
- A time block event is found by the stored time block activity (same title and start), because the block's event ID is not kept after the block.

## Review fix round 1

`EngineTrackerEventFixTests` (6 tests): ask-first survives a lock (G33), I was here after an idle meeting logs it once (G37), an event at the exact second of return is logged, a break ending while locked starts no running event, events are sorted after each read (the spy already sorts, so that test guards only).

## Needs

- Track I: in `trackerPromptState` (T1 file), call `fillEventAsk(&s)` for `.eventAsk`, so the ask-first popup gets `event`, title, and the category pick (`EventAskPopup` reads `state.event` and `state.draft.category`).
- Track I: when the tracker is turned off (`trackerPrefsChanged`), call `closeEventNote()`; else a note shown in that minute stays until the tracker is on again.
- Track I: `UIController` must show `TrackerNoteView` from `trackerNoteState()` on `showTrackerNote` and close it on `closeTrackerNote` (corner column, never takes the keyboard).
- Track I (optional): when a calendar is ticked in Settings, add its calendar-name category at once (rule 48). Now it is added the first time an event of that calendar is logged.
- No new constant needed (uses `Timing.eventNoteShow`, `Timing.minute`, `Timing.activityMinimum`).

## Blocked

None.
