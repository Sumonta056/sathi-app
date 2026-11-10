# I: Integration

Status: done, ready to merge

Plan and goals: `docs/specs/phase-17-plan.md` (section I). Contracts: [`CONTRACTS.md`](CONTRACTS.md).

## Notes from wave 0

- Fill: `Sources/SathiUI/Windows/UIController+Tracker.swift` (6 presenter methods).
- Pass `FileActivityStore`, `SystemPresenceMonitor`, `CarbonHotkeyRegistrar` into `Engine(...)` in `AppEnvironment`; flush the activity store in `applicationWillTerminate`.
- Wire export month (T5 closure → T2 builders, Downloads + Finder), the Reports tabs, the "My day" sidebar group, the menu slot, and "Quiet until" in the menu bar.

## Plan

1. Core: `askEveryMinutes` in `TrackerPromptState`; "Quiet until {time}" in `statusText`; backup keeps raw activity items; wave 0 minors (copy "Yes", "1 min" from `Timing`, decode checks, `spaceKeyName`).
2. Platform wiring: `AppEnvironment` passes `FileActivityStore`, `SystemPresenceMonitor`, `CarbonHotkeyRegistrar`; `applicationWillTerminate` flushes activities.
3. `UIController+Tracker*`: prompts A, C, ask-first in the corner (non-activating; A after Done or a session takes the keyboard), B and D centered with the keyboard, note F, end of day. Tracker panels always sit below buddy popups (G15).
4. Reports: Habits / Activities tabs, day and month actions wired to the engine, export month to Downloads.
5. Settings "My day" group with the tracker page; menu tracker slot and "Log activity".
6. Move private copy and constants of T4–T6 into `Copywriter` / `UIMetrics` / `Limits`; shared days-off card API.
7. `.claude/rules/storage.md` row; checks; 1 commit.

## Progress

- Core: `TrackerPromptState.askEveryMinutes` (C shows the user's value); menu bar "Quiet until {time}" in `statusText`; `Engine.exportActivityMonth(_:to:)` writes JSON + CSV.
- Wave 0 minors: copy "Yes" (was "Yes, log it"); note F line takes its minutes from `Timing.eventNoteShow`; `usualLength` must be a chip and start < end on decode, else defaults; `spaceKeyName` moved to `Copywriter.trackerSpaceKeyName`; key codes of `ShortcutCapture` moved to `Limits`, key names to `Copywriter.trackerNamedKeys`.
- Backup: already wired to the store; with `FileActivityStore` in `AppEnvironment` it now writes the real activities.
- `AppEnvironment`: `FileActivityStore`, `SystemPresenceMonitor`, `CarbonHotkeyRegistrar`; `applicationWillTerminate` flushes activities.
- `UIController+Tracker` / `+TrackerPanels`: A, C, ask-first in the corner as non-activating panels that become key only on a click in a text field (G64, rule 62); A after Done or a session (`switchFrom`/`resume`) activates and takes the keyboard, and gives it back on close (rule 13); B and D centered with the keyboard; note F in the corner from `trackerNoteState()` (fallback state from the note), closes after `Timing.eventNoteShow`; end of day centered, no keyboard. Tracker panels resize with their content and restack.
- G15: tracker corner panels always stay at the end of the corner column; a buddy popup that opens later is inserted above them.
- Reports: Habits / Activities tabs (`PillSegment`), Activities has Day / Month; actions wired to the engine; `openActivityReport` opens the Activities tab; Export month writes to Downloads and selects the files in Finder. Reports window is 44 pt taller for the tab row.
- Settings: "MY DAY" group with "Activity tracker" (on switch; no NEW badge, it did not fit the sidebar width) above Time blocks; `SettingsTab.tracker`.
- Menu: running activity row at the top of the cards; "Log activity" below the tool row when the tracker is on.
- Shared days-off card: `DaysOffSource` (accent, hint, upcoming, month, add, remove); `DaysOffCard`, `DayOffPicker`, `DayOffCalendar` use it; `TrackerDaysOffCard` deleted.
- Private copy/constants of T4–T6 moved: `trackerCategoriesPerRow`, tile min scale, bar widths, ribbon hidden scale (`UIMetrics`); "Close", "N days" (now "1 day"), "–", "No calendars found on this Mac.", "New category", "Days off", "Add a day off", "Pick a date", tracker days-off hint (`Copywriter`).
- `.claude/rules/storage.md`: `activities/YYYY-MM.json` row.
- Tests: `Tests/SathiCoreTests/Tracker/Integration/` (7), `Tests/SathiUITests/Tracker/Integration/` (16).

## Fix round 1

- A with Resume takes the keyboard only when the user caused it: `TrackerRuntime.promptByUser` (not saved), set by Done, Log activity / shortcut, and a session the user finished; a timed-out session gives `false` (`Engine.trackerPromptByUser`).
- Esc on the A panel is a no-op; the popup's `onExitCommand` skips at the picked switch time.
- One resize observer per tracker panel (old token removed first).
- Hours: `TrackerPrefs.setStart` / `setEnd` keep start before end (the other field moves by 1 slot); on decode only the end is repaired (start + 1 slot, clamped).
- `takeActivityReportDay()` reads and clears the asked day; Reports switches to it on appear and on each new ask.
- A prompt swap (B to D) keeps the app to give the keyboard back to; the hand-back runs after the swap.
- Export month never overwrites: `name (2).json`; each file is written on its own, and the written ones are shown.
- Centered prompts keep their first center point when they resize.
- Tests: `TrackerFixRoundTests` (7), `TrackerPresenterFixTests` (7).

## Deferred

- Backup keeps only decodable activity items (raw unknown items stay on disk but not in the backup). Needs a raw read API on `FileActivityStore`; storage change, wave 3.
- Away rows in the report: no Edit/Delete, no `awayPlace` in `ActivityEdit`. Model + engine change; wave 3 if wanted.
- Report edits that cross midnight are not refused (needs a new `ActivityEditResult` case and copy).
- The global hotkey stays registered while the user records a new shortcut (Carbon eats that combo while recording).
- A "PresenceEvent" for input-again (D shows up to 60 s late after idle Away).
- Late C copy "Done · pick when you switched" vs spec "Done": left as T4 built it; spec wording decision.
- Meeting category color = Meditation buddy color (design decision).

## Needs after C merge

- Done at merge: `trackerPromptState` calls `fillEventAsk(&s)`; test `TrackerCalendarWiringTests`.
- Done at merge: turning the tracker off calls `closeEventNote()`; test `TrackerCalendarWiringTests`.
- Done here: `UIController.showTrackerNote` shows `TrackerNoteView` from `engine.trackerNoteState()`; `closeTrackerNote` closes it.

## Needs

## Blocked
