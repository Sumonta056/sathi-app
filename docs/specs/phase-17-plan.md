# Phase 17 plan: Daily activity tracker

Spec (rules and goals): `docs/specs/phase-17-activity-tracker.md`. Test notes: `docs/specs/phase-17-test-notes.md`. Progress and start-here file: `PROGRESS.md`.
Design page (Demo, Flow, Goals, Decisions, Plan, Test notes, screens): https://claude.ai/artifact/YHqbbEbFiGvqgdGVHSzMjU

Branch: `feat/activity-tracker`. Each subplan runs the `/feature` loop (plan → approval → failing tests → code → checks → review) and ends with **1 commit** on the branch. Push and merge to `main` only when the user says so.

A subplan is done only when every goal in its list is met (its check passes) and the exit checks pass. The review reports each goal ID as met or not met.

## Subplan 1: Core and engine

Slices: 17a, 17b, 17k (engine part)

**Outcome:** The whole tracker works in SathiCore with no UI: data, saved files, and every rule of the Flow tab, driven by the fake clock.

**Work:**

- `SathiCore/Tracker/` models: `Activity`, `ActivityKind`, `TrackerPrefs`, `TrackerLiveState`, `PromptKind`, `SwitchTime` helpers
- `ActivityStore` port, `FileActivityStore`, `InMemoryActivityStore`; `activities/YYYY-MM.json`; backup includes it
- `Engine+Tracker*.swift`: asks, late answers, Skip, switch time, Away and idle (through a fake `PresenceMonitor`), break, time block, buddy session start and end, hours end, midnight, end-of-day trigger
- `Copywriter+Tracker`, `Limits`/`Timing` constants, decoding fixtures

**Goals that must be met:**

| ID | Goal | Check |
|---|---|---|
| G1 | After install or update the tracker is off, and no prompt shows until the user turns it on. | Engine test |
| G2 | No prompt shows outside tracker hours, on a non-tracker day, on a day off, during a break, or while a time block runs. | Engine test |
| G3 | A full-screen lock holds tracker prompts back. They show when it ends. | Engine test |
| G7 | C shows at start + expected length + ask offset. For an Open activity, C shows every askEvery. | Engine test |
| G8 | Yes, 15 min more / 5 min / 30 min set the next ask time to now + that time. | Engine test |
| G9 | Skip changes no data and asks again after askEvery. | Engine test |
| G10 | No tracker prompt closes by itself. Only note F closes, after 1 min. | Engine test |
| G11 | An answer 5 min or more late shows the late C with the waited minutes. | Engine test |
| G13 | The picked switch time ends the old activity and starts the new one at the same second. | Engine test |
| G17 | Only 1 activity runs. A new one ends the old one at that moment. | Engine test |
| G18 | An activity shorter than 60 s is not saved. | Engine test |
| G19 | Away ends the activity at the earlier of the Away start and its confirmed-until time. The rest is Not logged. | Engine test |
| G20 | An activity never crosses midnight. | Engine test |
| G21 | After tracker hours a running activity continues and C still asks. No new A shows. | Engine test |
| G24 | Take a break ends the activity. The break is Away · Break. D shows after the break. | Engine test |
| G49 | activities/YYYY-MM.json is written atomically with whole seconds and kept forever. An unreadable item is dropped and the others stay. Unknown fields are kept. | Unit test |
| G50 | Old prefs.json and state.json without tracker keys load the defaults. | Fixture test |
| G51 | The running activity and the open prompt survive a restart. | Engine test |
| G52 | The JSON backup includes the activity months. | Unit test |
| G54 | No repeating timer. Every wait comes from upcomingDeadlines(). | Code review |
| G57 | A reading, breathing, or gym session start ends the running activity and starts a buddy activity with the buddy category. | Engine test |
| G58 | No tracker prompt asks while a buddy session runs, also while a breathing session is paused. | Engine test |
| G59 | When a session ends, A opens at once with "Continue {last activity}" and the Started row. Sathi never continues the old activity without an answer. | Engine + view test |
| G60 | A water glass and a quick reminder make no activity. A buddy activity writes no calendar event. | Engine test |

**Exit checks:** `./scripts/test.sh` and `./scripts/lint.sh` pass. Manual test notes for this subplan pass.

**Commit:** `feat(tracker): core data and engine flow`

## Subplan 2: Mac and prompts

Slices: 17c, 17d, 17l

**Outcome:** You can use the tracker every day: real lock, sleep, and idle detection, the ⌥⌘Space shortcut, prompts A, B, C, D on screen, quiet time, and the conflict rules.

**Work:**

- `PresenceMonitor` (workspace notifications, `CGEventSource` idle at a deadline), `HotkeyRegistrar` (Carbon hot key)
- `SathiUI/Features/Tracker/`: prompt A (For, calendar tick, No popups, Started row), B, C (on time and late), D, the corner column order
- Quiet time: buddy reminders wait, menu bar "Quiet until"
- Menu "Log activity" and a minimal Settings row "Activity tracker: on/off" so the user can use the tracker before subplan 5 adds the full page

**Goals that must be met:**

| ID | Goal | Check |
|---|---|---|
| P1 | Logging an activity takes 1 click (recent chip) or text + Enter. | Manual |
| G4 | At the start of tracker hours with nothing running, A shows in the corner and does not take the keyboard. | Engine + view test |
| G5 | Text + Enter starts an activity with the default category, length, ask offset, and calendar setting. | View test |
| G6 | A recent chip fills the text and category of that activity. | View test |
| G12 | Done opens A at once with the Started row: 5-minute chips from the last answer to now, Now selected, the grid when there are more than 4 chips. | Engine + view test |
| G14 | The shortcut opens B from any app. Enter switches at that exact time. | Manual |
| G15 | A tracker prompt sits below buddy popups in the corner column. | View test |
| G16 | 1 soft sound plays when A or C shows, and none when sound is off. | Engine test |
| G22 | Lock, sleep, and a closed lid start Away at that moment. 30 min idle starts Away at the last input. | Engine test + manual |
| G23 | D shows on return inside tracker hours. I was here shows only after an idle Away and puts the activity back. | Engine + view test |
| G25 | Idle detection uses a deadline, never a repeating timer. | Code review + perf |
| G61 | A always shows For, Add to calendar with its menu, and No popups until it ends. | View test |
| G62 | Quiet time: no tracker prompt and no buddy popup until the expected end. Buddy reminders wait and then show. Quick reminders still show. Events are still logged. | Engine test |
| G63 | The shortcut, the menu, or Done ends quiet time at once. The menu bar shows "Quiet until {time}". | Engine + view test |
| G64 | When a prompt shows, the keyboard stays in the app that had it. | Manual |
| G65 | An event start beats a C ask at the same moment. A full-screen lock shows before a tracker prompt. | Engine test |

**Exit checks:** `./scripts/test.sh` and `./scripts/lint.sh` pass, `/perf-check` passes. Manual test notes for this subplan pass.

**Commit:** `feat(tracker): prompts, presence, shortcut, quiet time`

## Subplan 3: Calendar

Slices: 17e, 17j

**Outcome:** Activities go to your calendar when you tick it, and your calendar meetings log themselves.

**Work:**

- `CalendarWriter.delete`, `events(from:to:calendarIDs:)`, `EventKitCalendarWriter` changes, `SpyCalendarWriter`
- Save on end, update on edit, delete, "Not in calendar"
- Read ticked calendars: log and tell (note F), ask first, while away (D rows), first chip, category per calendar and per title, overlaps
- Remove "It never reads your events" from the time block page

**Goals that must be met:**

| ID | Goal | Check |
|---|---|---|
| P5 | A calendar meeting needs no typing at all. | Manual |
| G26 | Add to calendar is off by default. The menu lists writable calendars by account, like time blocks. | View test |
| G27 | When an activity with a calendar ends, Sathi saves 1 event with the real start and end and keeps the event ID. | Spy test + 1 real event |
| G28 | A report edit updates the event. A delete deletes it. A missing event changes only the log. | Spy test |
| G29 | A calendar failure never blocks the tracker. The row shows Not in calendar and Save. | Spy test |
| G30 | Calendar reading is off by default. Sathi reads only the ticked calendars. | Spy test |
| G31 | Sathi skips all-day, declined, and Sathi-written events. Free events count. | Spy test |
| G32 | Log and tell: at the event start the activity switches, note F shows for 1 min, and no C asks before the event end. | Engine test |
| G33 | Ask first: the prompt stays. Yes logs from the event start, also when late. | Engine test |
| G34 | Mac away during an event: Sathi logs it with no question and shows it in D. | Engine test |
| G35 | A running event that is not logged is the first chip in A and B. | View test |
| G36 | Category order: the pick for that event name, then the calendar's category, then the calendar name. | Engine test |
| G37 | Sathi never writes an event for an event activity. No event is logged 2 times. | Spy test |
| G38 | 2 events overlap: the first stays, and a note offers Switch. | Engine test |

**Exit checks:** `./scripts/test.sh` and `./scripts/lint.sh` pass. Manual test notes for this subplan pass.

**Commit:** `feat(tracker): calendar write and read`

## Subplan 4: Reports and end of day

Slices: 17f, 17g

**Outcome:** You see any day and any month, copy the standup and monthly texts, export the month, and get the end-of-day popup.

**Work:**

- Reports window tabs Habits and Activities
- Day view: arrows, date picker with dots, tiles, timeline, log with Edit, Fill, Add past
- Month view: day rows, totals, Copy monthly report, Export month (JSON and CSV to Downloads)
- `ReportBuilder` parts for activities in Core (pure, unit-tested); end-of-day popup with the ribbon

**Goals that must be met:**

| ID | Goal | Check |
|---|---|---|
| P2 | The standup text of any day is 1 click away. | Manual |
| P3 | The monthly report text is 1 click away. | Manual |
| P4 | The timeline of a day shows where the time went, with no hand notes. | Manual |
| G39 | The Activities tab opens any past day from the arrows or the calendar. Days with activities show a dot. | View test |
| G40 | Real work + Away + Not logged = the tracked span of the day. | Unit test |
| G41 | Edit, Fill, and Add past activity work and refuse an overlap. | Engine + view test |
| G42 | Copy for standup gives the text of rule 35. | Unit test |
| G43 | The Month view lists each day, a row opens that day, and Copy monthly report gives the text of rule 36. | Unit + view test |
| G44 | Export month writes JSON and CSV to Downloads and shows it in Finder, with no save panel. | Manual |
| G45 | The end-of-day popup shows 1 time a day, at the end of hours or after the last activity. The animation is 1.5 s at most and none with Reduce motion. | Engine test + perf |
| G53 | With the tracker on: idle CPU under 1%, memory in budget, under 10 wakeups a minute. | perf.sh |

**Exit checks:** `./scripts/test.sh` and `./scripts/lint.sh` pass, `/perf-check` passes. Manual test notes for this subplan pass.

**Commit:** `feat(tracker): activities report and end of day`

## Subplan 5: Settings, menu, and release

Slices: 17h, 17i

**Outcome:** The feature is complete and shippable: full settings page, menu row, docs, website, Definition of done.

**Work:**

- Settings "My day" group, Activity tracker page (all rows of rule 39, calendar events rows, categories)
- Menu row for the running activity with Done
- `CLAUDE.md` module map, `README.md`, website text and screenshots (`/sathi-website`)
- Full Definition of done, perf.sh, perf.sh --windows (user), ui-verifier

**Goals that must be met:**

| ID | Goal | Check |
|---|---|---|
| G46 | The settings page has every row of rule 39. A change applies at the next ask. | View test |
| G47 | Categories: add, rename, delete. A deleted category stays on old activities. | Unit test |
| G48 | The menu shows the running activity with Done, and Log activity opens B. | View test |
| G55 | Tests, lint, and the release build pass. No file over 200 lines. No comments. | test.sh, lint.sh |
| G56 | The time block page and the website no longer say "It never reads your events". | Manual |

**Exit checks:** `./scripts/test.sh` and `./scripts/lint.sh` pass, full Definition of done. Manual test notes for this subplan pass.

**Commit:** `feat(tracker): settings, menu, docs`
