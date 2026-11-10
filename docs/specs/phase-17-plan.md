# Phase 17 plan: Daily activity tracker (parallel)

Spec (rules and goals): `docs/specs/phase-17-activity-tracker.md`. Test notes: `docs/specs/phase-17-test-notes.md`. Start-here and status: `PROGRESS.md`.
Design page (Demo, Flow, Goals, Decisions, Plan, Test notes, screens): https://claude.ai/artifact/YHqbbEbFiGvqgdGVHSzMjU

The work runs in 4 waves. Wave 0 fixes every shared type and fills every shared file. Wave 1 runs 6 tracks in parallel, each in its own git worktree and branch, and each owns only new files. Wave 2 runs 2 tracks in parallel. Wave 3 finishes.

| Wave | Tracks | Parallel | Wall time (estimate) |
|---|---|---|---|
| 0 | Contracts | 1 | 1.5–2 h |
| 1 | T1 Engine flow, T2 Storage, T3 Mac platform, T4 Prompt views, T5 Reports and end of day, T6 Settings and menu views | 6 | 5–7 h |
| 2 | C Calendar engine, I Integration | 2 | 3–4 h |
| 3 | Finish | 1 + user | 2–3 h |
| | **Total** | | **about 12–16 h (3–4 days)** |

## Merge conflict rules (read before any edit)

1. **Base branch:** `feat/activity-tracker`. Each track works on its own branch in its own worktree: `git worktree add <path> -b <track branch> feat/activity-tracker`.
2. **File ownership:** a track creates and edits **only** the files in its "Owns" row. It never edits a file that already exists on the base branch, and never a file that another track owns.
3. **Shared files are frozen after wave 0.** These files change only in wave 0 or in wave 2 track I: `Limits.swift`, `Timing.swift`, `StorageKeys.swift`, `SoundName.swift`, every `Copywriter*.swift`, every `UIMetrics*.swift`, `NightPalette.swift`, `Engine.swift`, `LiveState.swift`, `Prefs.swift`, `GeneralPrefs.swift`, every file in `Ports/`, every file in `Tests/SathiTestSupport/`, `AppEnvironment.swift`, every `UIController*.swift`, `ReportsView.swift`, `SettingsSidebar.swift`, the menu panel files, `Package.swift`, `CLAUDE.md`, `GLOSSARY.md`, `docs/`, `PROGRESS.md`.
4. **Need a shared change?** Do not make it. Write it under "Needs" in your track file `docs/tracker-progress/<track>.md` and go on with a local workaround in your own files (for example a private constant). Track I (wave 2) or a contract fix does the shared change.
5. **Contract defect** (a wave 0 type or signature is wrong): stop the track, write it under "Blocked" in the track file. The controller fixes it with 1 commit on the base branch, and every running track rebases: `git rebase feat/activity-tracker`.
6. **Status:** each track writes only its own `docs/tracker-progress/<track>.md`. Only the merge step edits `PROGRESS.md`. So 2 tracks never edit the same status file.
7. **Done means:** the track's tests and `./scripts/lint.sh` pass in its worktree, every goal in its list is met, a review found no Critical or Important issue, and the branch is rebased on the newest base with no conflict. Then 1 commit: `feat(tracker): <track name>`.
8. **Merge order** (wave 1): T2 → T1 → T3 → T4 → T5 → T6. Merge with `git merge --no-ff`. After each merge run `./scripts/test.sh` and `./scripts/lint.sh` on the base. A failure stops the merges.
9. **A merge conflict** can only happen if a rule above was broken. Do not resolve it by guess. Abort the merge (`git merge --abort`), write it in `PROGRESS.md` under "Open items", and ask the user.
10. **Push** only when the user says so. Cloud sessions need the base branch on GitHub first.

## Wave 0: Contracts (1 session)

Branch: `feat/activity-tracker` directly (no worktree).

Builds the shared base so that every wave 1 track compiles alone:
- `Sources/SathiCore/Tracker/`: `Activity`, `ActivityKind`, `ActivityID`, `TrackerPrefs` (all fields of the spec Storage section, lenient decoding), `TrackerLiveState`, `RunningActivity`, `PromptKind`, `PromptState`, `AwayPlace`, `EventMode`, `TrackerPromptState` (the plain view state that prompt views read), `ActivityDay` and `ActivityMonth` value types.
- `Prefs.tracker`, `LiveState.tracker` fields with defaults (no schema bump), plus a fixture test that old files still load.
- Ports: `ActivityStore`, `PresenceMonitor`, `HotkeyRegistrar`, `CalendarWriter.delete` and `events(from:to:calendarIDs:)` with `CalendarEventInfo`; tracker methods on `ReminderPresenter` (show and close each prompt, note F, end of day).
- Test support: `InMemoryActivityStore`, `FakePresenceMonitor`, `SpyHotkeyRegistrar`, `SpyCalendarWriter` additions, `SpyPresenter` tracker calls, `EngineHarness` tracker setup.
- `Engine` stored state for the tracker and `Engine+TrackerAPI.swift` with every public action as a stub (it does nothing yet). Wave 1 track T1 fills the stubs.
- All constants (`Limits`, `Timing`), all copy (`Copywriter+Tracker*.swift`), `UIMetrics+Tracker*.swift`, the tracker colors in `NightPalette`, storage keys.
- Empty folders with a `.gitkeep` are not needed; each track creates its own folders.
- `docs/tracker-progress/` with 1 file for each track (status: not started).

Done: `swift build`, `./scripts/test.sh`, and `./scripts/lint.sh` pass, and nothing in the app changes (the tracker is off and no code calls it). 1 commit: `feat(tracker): wave 0 contracts`.

## Wave 1: 6 tracks in parallel

### T1: Engine flow

Branch `feat/tracker-t1-engine`, worktree `../Sathi-t1`.
**Owns:** `Sources/SathiCore/Engine/Engine+Tracker*.swift` (except `Engine+TrackerCalendar*.swift`), `Sources/SathiCore/Tracker/Rules/`, `Tests/SathiCoreTests/Tracker/Engine/`.
**Work:** Spec rules 1–27, 53–64 (engine side). Asks, late answers, Skip, switch time, Away and idle (with `FakePresenceMonitor`), break, time block, hours end, midnight, end-of-day trigger, buddy sessions, quiet time, conflicts, restart restore.
**Tests:** `./scripts/test.sh SathiCoreTests`.

| Goal | Text |
|---|---|
| G1 | After install or update the tracker is off, and no prompt shows until the user turns it on. |
| G2 | No prompt shows outside tracker hours, on a non-tracker day, on a day off, during a break, or while a time block runs. |
| G3 | A full-screen lock holds tracker prompts back. They show when it ends. |
| G4 | At the start of tracker hours with nothing running, A shows in the corner and does not take the keyboard. |
| G7 | C shows first at the earlier of start + askEvery and start + expected length + ask offset. For an Open activity, C shows every askEvery. A change of Ask every applies at once. |
| G8 | Yes, 15 min more / 5 min / 30 min set the next ask time to now + that time. |
| G9 | Skip changes no data and asks again after askEvery. |
| G10 | No tracker prompt closes by itself. Only note F closes, after 1 min. |
| G11 | An answer 5 min or more late shows the late C with the waited minutes. |
| G12 | Done opens A at once with the Started row: 5-minute chips from the last answer to now, Now selected, the grid when there are more than 4 chips. |
| G13 | The picked switch time ends the old activity and starts the new one at the same second. |
| G16 | 1 soft sound plays when A or C shows, and none when sound is off. |
| G17 | Only 1 activity runs. A new one ends the old one at that moment. |
| G18 | An activity shorter than 60 s is not saved. |
| G19 | Away ends the activity at the earlier of the Away start and its confirmed-until time. The rest is Not logged. |
| G20 | An activity never crosses midnight. |
| G21 | After tracker hours a running activity continues and C still asks. No new A shows. |
| G23 | D shows on return inside tracker hours. I was here shows only after an idle Away and puts the activity back. |
| G24 | Take a break ends the activity. The break is Away · Break. D shows after the break. |
| G51 | The running activity and the open prompt survive a restart. |
| G54 | No repeating timer. Every wait comes from upcomingDeadlines(). |
| G57 | A reading, breathing, or gym session start ends the running activity and starts a buddy activity with the buddy category. |
| G58 | No tracker prompt asks while a buddy session runs, also while a breathing session is paused. |
| G59 | When a session ends, A opens at once with "Continue {last activity}" and the Started row. Sathi never continues the old activity without an answer. |
| G60 | A water glass and a quick reminder make no activity. A buddy activity writes no calendar event. |
| G62 | Quiet time: no tracker prompt and no buddy popup until the expected end. Buddy reminders wait and then show. Quick reminders still show. Events are still logged. |
| G63 | The shortcut, the menu, or Done ends quiet time at once. The menu bar shows "Quiet until {time}". |
| G65 | An event start beats a C ask at the same moment. A full-screen lock shows before a tracker prompt. |

### T2: Storage

Branch `feat/tracker-t2-storage`, worktree `../Sathi-t2`.
**Owns:** `Sources/SathiCore/Storage/*Activit*.swift`, `Sources/SathiCore/Export/*Activit*.swift`, `Tests/SathiCoreTests/Tracker/Storage/`, `Tests/SathiCoreTests/Fixtures/tracker/`.
**Work:** Storage section of the spec. `FileActivityStore` (atomic, whole seconds, keep unknown fields, drop unreadable items), month files, fixtures for old prefs and state, backup includes activity months.
**Tests:** `./scripts/test.sh SathiCoreTests`.

| Goal | Text |
|---|---|
| G49 | activities/YYYY-MM.json is written atomically with whole seconds and kept forever. An unreadable item is dropped and the others stay. Unknown fields are kept. |
| G50 | Old prefs.json and state.json without tracker keys load the defaults. |
| G52 | The JSON backup includes the activity months. |

### T3: Mac platform

Branch `feat/tracker-t3-platform`, worktree `../Sathi-t3`.
**Owns:** `Sources/SathiUI/Platform/Presence*.swift`, `Sources/SathiUI/Platform/Hotkey*.swift`, `Sources/SathiUI/Platform/EventKitCalendarReader*.swift`, `Tests/SathiUITests/Tracker/Platform/`.
**Work:** Ports section of the spec. `SystemPresenceMonitor` (workspace and distributed notifications, `CGEventSource` idle read at a deadline), `CarbonHotkeyRegistrar`, EventKit read of events and delete of an event (new files; the existing `EventKitCalendarWriter` gets its new methods through an extension file).
**Tests:** `./scripts/test.sh SathiUITests`, then a hand test of lock, sleep, and ⌥⌘Space with a debug log.

| Goal | Text |
|---|---|
| G14 | The shortcut opens B from any app. Enter switches at that exact time. |
| G22 | Lock, sleep, and a closed lid start Away at that moment. 30 min idle starts Away at the last input. |
| G25 | Idle detection uses a deadline, never a repeating timer. |

### T4: Prompt views

Branch `feat/tracker-t4-prompts`, worktree `../Sathi-t4`.
**Owns:** `Sources/SathiUI/Features/Tracker/Prompts/`, `Tests/SathiUITests/Tracker/Prompts/`.
**Work:** Rules 12–18, 44–47, 55, 58 (view side). Views A (For, calendar tick and menu, No popups, Started row, summary line), B, C (on time, late), D (plain, idle, while-away rows), F (log and tell, ask first), the "Continue" form of A. Each view takes a plain view-state value and closures from `TrackerPromptState` (wave 0), so it needs no Engine.
**Tests:** `./scripts/test.sh SathiUITests`.

| Goal | Text |
|---|---|
| G5 | Text + Enter starts an activity with the default category, length, ask offset, and calendar setting. |
| G6 | A recent chip fills the text and category of that activity. |
| G35 | A running event that is not logged is the first chip in A and B. |
| G61 | A always shows For, Add to calendar with its menu, and No popups until it ends. |
| P1 | Logging an activity takes 1 click (recent chip) or text + Enter. |

### T5: Reports and end of day

Branch `feat/tracker-t5-reports`, worktree `../Sathi-t5`.
**Owns:** `Sources/SathiCore/Stats/Activity*.swift`, `Sources/SathiUI/Features/Reports/Activities/`, `Sources/SathiUI/Features/Tracker/EndOfDay/`, `Tests/SathiCoreTests/Tracker/Reports/`, `Tests/SathiUITests/Tracker/Reports/`.
**Work:** Rules 26, 32–37. Core: day and month builders, totals, Not logged gaps, standup and monthly texts, CSV and JSON month export. UI: Activities Day and Month views, date picker with dots, log rows with Edit, Fill, Add past, the end-of-day popup view with the ribbon. The tab switch in the Reports window is wave 2.
**Tests:** `./scripts/test.sh`.

| Goal | Text |
|---|---|
| G39 | The Activities tab opens any past day from the arrows or the calendar. Days with activities show a dot. |
| G40 | Real work + Away + Not logged = the tracked span of the day. |
| G41 | Edit, Fill, and Add past activity work and refuse an overlap. |
| G42 | Copy for standup gives the text of rule 35. |
| G43 | The Month view lists each day, a row opens that day, and Copy monthly report gives the text of rule 36. |
| G44 | Export month writes JSON and CSV to Downloads and shows it in Finder, with no save panel. |
| G45 | The end-of-day popup shows 1 time a day, at the end of hours or after the last activity. The animation is 1.5 s at most and none with Reduce motion. |
| P2 | The standup text of any day is 1 click away. |
| P3 | The monthly report text is 1 click away. |
| P4 | The timeline of a day shows where the time went, with no hand notes. |

### T6: Settings and menu views

Branch `feat/tracker-t6-settings`, worktree `../Sathi-t6`.
**Owns:** `Sources/SathiUI/Features/Settings/Tracker/`, `Sources/SathiUI/Features/MenuBar/Tracker*.swift`, `Tests/SathiUITests/Tracker/Settings/`.
**Work:** Rules 38–41 and the calendar rows of rules 42–48. The Activity tracker page, categories editor, calendar events rows, menu row with Done, "Log activity" button. The sidebar entry and the menu slot are wave 2.
**Tests:** `./scripts/test.sh SathiUITests`.

| Goal | Text |
|---|---|
| G46 | The settings page has every row of rule 39. A change applies at the next ask. |
| G47 | Categories: add, rename, delete. A deleted category stays on old activities. |
| G48 | The menu shows the running activity with Done, and Log activity opens B. |

## Wave 2: 2 tracks in parallel

Start only after all 6 wave 1 tracks are merged.

### C: Calendar engine

Branch `feat/tracker-c-calendar`, worktree `../Sathi-c`.
**Owns:** `Sources/SathiCore/Engine/Engine+TrackerCalendar*.swift`, `Sources/SathiCore/Tracker/Calendar/`, `Tests/SathiCoreTests/Tracker/Calendar/`.
**Work:** Rules 28–31 and 42–52: save on end, update on edit, delete, "Not in calendar", read ticked calendars, log and tell, ask first, while away, first chip, category per calendar and per title, overlaps.
**Tests:** `./scripts/test.sh SathiCoreTests`, then 1 real Gmail event (user).

| Goal | Text |
|---|---|
| G26 | Add to calendar is off by default. The menu lists writable calendars by account, like time blocks. |
| G27 | When an activity with a calendar ends, Sathi saves 1 event with the real start and end and keeps the event ID. |
| G28 | A report edit updates the event. A delete deletes it. A missing event changes only the log. |
| G29 | A calendar failure never blocks the tracker. The row shows Not in calendar and Save. |
| G30 | Calendar reading is off by default. Sathi reads only the ticked calendars. |
| G31 | Sathi skips all-day, declined, and Sathi-written events. Free events count. |
| G32 | Log and tell: at the event start the activity switches, note F shows for 1 min, and no C asks before the event end. |
| G33 | Ask first: the prompt stays. Yes logs from the event start, also when late. |
| G34 | Mac away during an event: Sathi logs it with no question and shows it in D. |
| G36 | Category order: the pick for that event name, then the calendar's category, then the calendar name. |
| G37 | Sathi never writes an event for an event activity. No event is logged 2 times. |
| G38 | 2 events overlap: the first stays, and a note offers Switch. |
| P5 | A calendar meeting needs no typing at all. |

### I: Integration

Branch `feat/tracker-i-integration`, worktree `../Sathi-i`.
**Owns:** the shared files of rule 3 that wire the feature: `AppEnvironment.swift`, `UIController+Tracker*.swift` (new) and `UIController.swift`, `ReportsView.swift` (Habits and Activities tabs), `SettingsSidebar.swift` ("My day" group), the menu panel (tracker row slot, "Log activity"), the `ReminderPresenter` implementation, the corner column order, non-activating panels, "Quiet until" in the menu bar, plus every "Needs" item from the wave 1 track files.
**Work:** connect the Engine to real windows and real platform adapters. After this wave the app runs the tracker end to end.
**Tests:** `./scripts/test.sh`, `./build.sh --install`, `/perf-check`.

| Goal | Text |
|---|---|
| G15 | A tracker prompt sits below buddy popups in the corner column. |
| G64 | When a prompt shows, the keyboard stays in the app that had it. |

## Wave 3: Finish

Branch `feat/activity-tracker`. 1 session plus the user.
- The final whole-branch review against all 70 goals. It lists each goal ID as met or not met.
- The manual test notes of `docs/specs/phase-17-test-notes.md` (the user runs them).
- `./scripts/perf.sh` and `./scripts/perf.sh --windows` (user, in Terminal).
- `CLAUDE.md` module map, `README.md`, the website (`/sathi-website`), and the removal of "It never reads your events".
- 1 commit: `docs(tracker): finish phase 17`. Merge to `main` and push only when the user says so.

| Goal | Text |
|---|---|
| G53 | With the tracker on: idle CPU under 1%, memory in budget, under 10 wakeups a minute. |
| G55 | Tests, lint, and the release build pass. No file over 200 lines. No comments. |
| G56 | The time block page and the website no longer say "It never reads your events". |
