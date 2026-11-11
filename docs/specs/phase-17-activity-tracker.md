# Phase 17: Daily activity tracker

Phase 18 replaces the prompt layouts (rules 12, 13, 15–19, 44 places, 47 chips) with the one activity prompt: `docs/specs/phase-18-app-window.md` rules 41–54.

Sathi asks the user at set times what they are doing now. One answer is 1 click or a short text. Sathi keeps the answers for each day, shows the day and the month in Reports, and can write each activity to a calendar. In the long term the tracker replaces time blocks (`docs/adr/0001-activity-tracker-replaces-time-blocks.md`).

Design (screens and flow): https://claude.ai/artifact/YHqbbEbFiGvqgdGVHSzMjU (tabs Flow, Prompts, End of day, Report · Day, Report · Month, Settings). First canvas: https://claude.ai/artifact/AG2GNswCL7A9nvF3dqimHw.
Terms: `GLOSSARY.md` (Daily activity tracker, Activity, Expected length, Activity prompt, Away, Not logged).

## Why

The user does many different things in a work day and keeps notes by hand to track them. The notes are hard to keep. The tracker collects the same facts with almost no typing and gives 3 outputs: a standup text, hours per category, and a timeline of the day.

## Rules

### Activity

1. An activity has a text, an optional category, a start, and an end. Only 1 activity runs at a time. A new activity ends the running one at that moment.
2. Text is trimmed, and line breaks become spaces. Empty text is refused. The maximum is `Limits.activityTextMax` (80) characters.
3. Expected length: a chip from `Limits.activityLengths` (15, 30, 60 min) or Open. The default is `TrackerPrefs.usualLength` (30). The activity does not end at its expected length. Sathi only asks.
4. Ask me: "When it ends" (default), "5 min after", or "15 min after" (`Limits.askOffsets` 0, 5, 15). It moves the first "Still on it?" after the expected length.
5. An activity shorter than `Timing.activityMinimum` (60 s) is not saved.
6. Not logged is never stored. It is every gap inside tracker hours that has no activity and no Away.
7. The tracker is not a habit: no streak, no goal, no `HabitID`, no history event, no row in the 10 PM day summary.

### When the tracker is quiet

8. The tracker asks only when all are true: `TrackerPrefs.isOn` (default off, so an update never starts popups), now is inside tracker hours (default 09:00–18:00), today is a tracker weekday (default Mon–Fri) and not a tracker day off, Sathi is not on a break, and no time block runs.
9. A full-screen lock of any buddy or quick reminder holds tracker prompts back. They show when the lock ends.
10. Take a break: the running activity ends at the break start. The break is Away with the place "Break". When the break ends inside tracker hours, prompt D shows.
11. A time block runs: no prompt asks. When the block ends and is saved, Sathi adds a read-only activity with the block title, no category, and its start and end. A running activity ends when a time block starts.

### Prompts

12. There are 4 prompts. Each one stays until the user acts. None goes away by itself. Only 1 tracker prompt shows at a time.

| Prompt | Where | Takes the keyboard | When it shows |
|---|---|---|---|
| A · What now? | Corner column | Only after a click in it | Nothing runs, at the ask time (rule 13) |
| B · Center panel | Screen center | Yes | The shortcut, or "Log activity" in the menu |
| C · Still on it? | Corner column | No | A running activity reaches its ask time (rule 14) |
| D · Welcome back | Screen center | Yes | Away ends inside tracker hours (rule 18) |

13. A shows when nothing runs and: tracker hours start, `askEvery` (default 15 min) passes after a Skip of A, or a "Done" in C (then A opens at once in the same place and takes the keyboard, because the user just clicked).
13a. Switch time: when A opens right after Done, it shows a "Started" row that is always open. Its chips are 5 minutes apart, from the last answer time of the old activity (its Start or its last "Yes") up to now. "Now" is the default. With more than 4 chips, the row shows the `TimeMenu` grid. The picked time ends the old activity and starts the new one, so there is no gap and no overlap. Skip in this A ends the old activity at the picked time.
14. C shows first at the earlier of `start + askEvery` and `start + expected length + ask offset`, then at each time the user picks in C. For an Open activity it shows every `askEvery`. An activity from a calendar event, a buddy session, or with quiet time keeps `start + expected length + ask offset`.
14a. A change of "Ask every" in Settings applies at once. For a running work activity the pending ask time moves by the difference between the new and the old value, not before now, and before the first answer not after `start + expected length`. With nothing running, a pending A after a Skip moves by the difference. During quiet time (rule 58) the ask time stays at the expected end and a change does not move it. The confirmed-until time (rule 22) does not change.
15. C on time: "Yes, 15 min more" (big button, uses `askEvery`), "Or more" with the chips "5 min" and "30 min", "Done · pick when you switched", and "Skip". The header shows "STILL ON IT? · {n} MIN SO FAR" and the activity text with its category dot. Done opens A at once with the Started row (rule 13a); the old activity ends at the picked switch time on Start or Skip in A. Skip closes C and asks again after `askEvery`, without a change to data.
16. C late: when the user answers `Timing.lateAnswer` (5 min) or more after C showed, C shows "This question waited {n} min.", "Still on it" (the activity continues to now), and "Done · pick when you switched" (opens A with the Started row of rule 13a).
17. A and B: text field, then a "Recent" dropdown with up to 10 recent activities (`Limits.recentMax` 10, newest first, the same text and category once; each row shows the category color dot and name; a calendar event that runs now is the first row). Always visible, with no panel to open: the For chips, a Category dropdown (✓ on the selected category, "No category" at the end), the Ask me chips, an "Add to calendar" check box with the calendar menu, and a "No popups until it ends" switch (rule 58). A pick in the Recent dropdown starts that activity at once, with its text and category. Enter starts. A has Start and Skip. B has Esc to close and a key hint line. The tracker accent color is light red `#FF8A80` (text on it `#2A0E0C`).
18. D asks the reason first, then what to do. Title "Welcome back. Where were you?". Step 1 "Where were you?": the place chips (Lunch, Meeting, Walk, Commute, Other), 1 chip for each user-made place, and "+ Add". "+ Add" opens a text field; the new place is saved in `TrackerPrefs.awayPlaces` (max `Limits.awayPlaceMax` 8, name max `Limits.awayPlaceNameMax` 24, no built-in name, no duplicate) and is picked at once. The user removes a place in Settings → Activity tracker → Away places. A line shows what Sathi saves: "Sathi saves {start} – {end} as Away · {place}". A pick shows as selected at once and is saved on the Away item (`awayPlace`; a user-made place is `.other` with `awayPlaceName`). The reason is optional. Step 2 "What now?": "Continue {last activity}" (Enter), "Start something new" (shows the text field in place), and "I was here", which shows only when Away came from idle; it removes that Away and continues the last activity from its start. Esc keeps the Away.
19. A prompt and a buddy popup due at the same time both show in the corner column. The tracker prompt goes below the buddy popups.
20. Sound: 1 soft tap when A or C shows, when `TrackerPrefs.playsSound` (default on) and General sound is on.

### Away

21. Away starts when the screen locks, the Mac sleeps, the lid closes, or there is no mouse or key input for `TrackerPrefs.idleMinutes` (default 30). For idle, Away starts at the last input time.
22. Each running activity has a confirmed-until time: the next ask time after a Start or a "Yes". A skipped or unanswered C does not move it. A late "Still on it" moves it to now. Away ends the activity at the earlier of the Away start and its confirmed-until time. The time between is Not logged. A late "Still on it" confirms the activity only up to now.
22a. An activity from a calendar event (kind `event`) does not end at the Away start. It runs to the earlier of the event end and the return, and the Away items are cut around it. When the user returns before the event end, D does not show and the event activity goes on. A buddy activity (kind `buddy`, rule 53) is kept the same way while its session exists, also when paused: it runs on through Away, the Away items are cut around it, and D does not show while the session still runs (rule 54). A resume or the session end counts as the return from an idle Away. Away items are never stored over a logged activity.
23. Away inside tracker hours is saved as an Away item. Its place is empty until the user picks one in D or in the report.
24. Away time outside tracker hours is not saved.

### Day edges

25. At the end of tracker hours no new A shows. A running activity continues, and C still asks on a tracker day. C never asks on a non-tracker day or a day off.
26. The end-of-day popup shows 1 time a day (`LiveState.tracker.lastEndOfDay`), when `TrackerPrefs.endOfDayOn` (default on): at the end of tracker hours if nothing runs, or else right after the running activity ends. It shows the animated timeline (at most 1.5 s, none with Reduce motion), totals, "Copy for standup", "Open full report", and "Close". It is a centered popup that does not take the keyboard.
27. At midnight a running activity ends at the earlier of 00:00 and its confirmed-until time (rule 22), because Sathi never adds time that the user did not confirm. An activity never crosses midnight.

### Calendar

28. "Add to calendar" is off by default (`TrackerPrefs.calendarOnByDefault`). The calendar menu shows the writable calendars grouped by account, like the time block menu. The default is `TrackerPrefs.defaultCalendarID`. A change applies to that activity only.
29. When an activity with a calendar ends, Sathi saves 1 event with its real start and end and keeps the event ID. It uses the `CalendarWriter` port of phase 13.
30. An edit in the report (text, category, start, end) updates the event. A delete deletes the event. A missing event changes only the log and shows nothing.
31. Calendar gone, no access, or a failed save: the activity is saved without an event, and the log row shows "Not in calendar" with a "Save" button. The tracker never blocks on the calendar.

### Calendar events (read)

42. Reading is off by default (`TrackerPrefs.readsEvents`). The user ticks the calendars to read (`readCalendarIDs`). Settings text: "Sathi reads events only from the calendars you tick, only on this Mac." The time block text "It never reads your events" is removed from the app and the website.
43. Sathi uses timed events from the ticked calendars, inside tracker hours, on tracker days. It skips all-day events, events that the user declined, and events that Sathi wrote (the saved event IDs of activities and time blocks). Events marked Free count.
44. At an event start, with `eventMode` `.logAndTell` (default): the running activity ends at the event start. A new activity starts with the event title, the event start, and the event end as its expected end. No "Still on it?" asks before the event end. Note F shows in the corner column: "FROM YOUR CALENDAR · {time}", the title, "{start} – {end} · {calendar}", a Category dropdown, "Not attending", "Undo", and the line "Logged now · this note closes in 1 min". It never takes the keyboard and closes after `Timing.eventNoteShow` (1 min), because it asks nothing. Undo removes the event activity and continues the old one. Not attending removes it and opens A with the Started row from the event start.
45. With `eventMode` `.askFirst`: a C-style prompt "{title} started. Log it?" with "Yes" and "No". It stays until the user answers. Yes logs from the event start, also when the answer is late. A late Yes cuts work only inside the event, from its start to the earlier of its end and now; work after the event end stays. When the event has already ended, Yes saves it as a finished item and the running activity goes on from the event end.
46. The Mac is away at the event start (both modes): Sathi logs the event from its start, with no question. The Away ends at the event start. If the Mac is still away at the event end, Away starts again at the event end. On return, D shows "While you were away" with 1 row for each logged event and "Not attending" on each row.
47. When A or B opens while an event runs that is not logged, the event is the first chip.
48. Category, in this order: the last category the user picked for the same event title; else the category of its calendar (`categoryByCalendar`). A ticked calendar gets, by default, a category with the calendar name and color (for example "Gmail Work"), added to the category list. In Settings the user can map a calendar to any category instead (for example "Cefalo" → Cefalo Meetings, a learning calendar → Learning). Note F and the ask-first prompt show category chips to change it.
49. Sathi never writes a calendar event for an activity that came from an event. The activity stores `sourceEventID`.
50. 2 events overlap: the first one stays. At the second start, a quiet note says "Also now: {title}" with "Switch".
51. At the event end, A opens with the Started row from the event end. The user can click the event chip if the meeting still runs. A press of the shortcut during the event ends it at that moment, like any switch.
52. Sathi reads the events again at each ask time and at each event start. It never polls. `upcomingDeadlines()` adds the next event start of the day. A moved or deleted event changes the plan; an event deleted after Sathi logged it keeps its activity.

### Buddy sessions

53. When a reading, breathing, or gym session starts inside tracker hours, the running activity ends at that moment. An activity of kind `buddy` starts: text "Breathing · {pattern}", "Reading", or "Gym · {workout idea}"; category = the buddy (Meditation, Reading, Gym), added to the category list with the buddy color.
54. While a buddy session runs (a breathing pause included), no tracker prompt asks.
55. When the session ends (done or stopped), its activity ends. If an activity ran before it, A opens at once with a big "Continue {text}" button (Enter) above the text field, and the Started row from the session end. Continue starts that activity again as a new item from the session end. Else A opens as usual. Sathi never returns to the old activity without a question.
56. A water glass and a quick reminder make no activity, because they have no length.
57. A buddy activity never writes a calendar event. Buddy history and streaks do not change.

### Quiet time and conflicts

58. Quiet time: the "No popups until it ends" switch in A or B (off by default; it needs a length, so it is off for Open). Until the expected end: no tracker prompt asks, buddy reminders wait and show at the end (none is lost, and a wait is not a snooze), and note F does not show (events are still logged). Quick reminders still show, as during a break. The menu bar shows "Quiet until {time}".
59. At the end of quiet time, C asks as usual, then the waiting buddy reminders show in the corner column.
60. The shortcut, the menu, or Done in the menu ends quiet time at once.
61. A macOS notification banner may cover a Sathi popup for a few seconds. Sathi popups never close by themselves, so nothing is lost. Sathi does not move its popups for banners.
62. A and C never take the keyboard when they show, so typing in another app goes on there.
63. An event start and a C ask at the same moment: the event wins. C is dropped, because its activity ended at the event start.
64. A full-screen lock and a tracker prompt at the same moment: the lock shows first, and the prompt shows after it (rule 9).

### Report

32. The Reports window gets 2 top tabs: Habits (the current report) and Activities.
33. Activities · Day: ‹ › arrows and a date button with a month calendar. Days with activities have a dot. 4 tiles: Real work, Top category, Activities (with "{n} in your calendar"), Away (with Not logged). A timeline of tracker hours, the activity log with Edit and Fill, "+ Add past activity", totals by category, and "Copy as text" (standup text).
33a. Away rows also have Edit and Delete. The Away edit changes the place, the start, and the end.
33b. An edit or a past activity whose start and end are on different days is refused with "An activity cannot cross midnight." (rule 27).
34. Activities · Month: 4 tiles (Real work, Average day, Best day, Away), 1 row per day with a small timeline strip (a click opens that day), totals by category, "Copy monthly report", and "Export month" (JSON and CSV, saved to `~/Downloads` and shown in Finder, so no save panel).
35. Standup text: "{date} · {real work}", then 1 line per text and category, longest first: "• {text} ({category}) · {length}".
36. Monthly report text: "{month} · {days} days tracked · {real work}", "Average {length} a day", 1 line per category with %, then 1 line per day: "{date} · {real work} · {top 3 texts}".
37. Week view and edits that move many items at once are later (phase 2 of the tracker).

### Settings

38. A new sidebar group "My day" holds "Activity tracker" and, below it, "Time blocks". No NEW badge (it does not fit the sidebar width).
39. Activity tracker page: on/off, Hours (the `TimeMenu` 5-minute grid), Days and days off (the shared `WeekdayRow` and `DaysOffCard`), Ask every (`Limits.trackerAskChips` 10, 15, 20, 30, 60), Usual length, Away after (`Limits.idleChips` 10, 20, 30, 60), Categories (add, rename, delete, color; at most `Limits.categoryMax` 12), Calendar (access, on by default, default calendar), Keyboard shortcut (default ⌃⌥⌘Space, Change), "Show my day when tracker hours end", and "Sound with each prompt".
40. A deleted category stays on old activities as text. New activities cannot pick it.

### Menu

41. When the tracker is on, the menu shows 1 tracker card at the top. When an activity runs: dot, text, "since {time} · {length}", "Done", then a divider and "Switch activity" (opens B) with the shortcut hint and "Next ask {time}". When nothing runs: "Not tracking now", "Next ask {time}" when known, and "Log activity" (opens B). "Next ask" is the time of the next A or C (the later of the ask time and the quiet end); it is hidden while a prompt shows or the Mac is away.

## Goals (acceptance)

Each slice review checks these goals by ID. A goal is met only when its check passes. The same list is in the Goals tab of the design page.

| ID | Goal | Rules | Slice | Check |
|---|---|---|---|---|
| P1 | Logging an activity takes 2 clicks (Recent dropdown, then a row) or text + Enter. | 17, 13a | 17d | Manual |
| P2 | The standup text of any day is 1 click away. | 35 | 17f | Manual |
| P3 | The monthly report text is 1 click away. | 36 | 17f | Manual |
| P4 | The timeline of a day shows where the time went, with no hand notes. | 33 | 17f | Manual |
| P5 | A calendar meeting needs no typing at all. | 44, 46 | 17j | Manual |
| G1 | After install or update the tracker is off, and no prompt shows until the user turns it on. | 8 | 17b | Engine test |
| G2 | No prompt shows outside tracker hours, on a non-tracker day, on a day off, during a break, or while a time block runs. | 8, 11 | 17b | Engine test |
| G3 | A full-screen lock holds tracker prompts back. They show when it ends. | 9 | 17b | Engine test |
| G4 | At the start of tracker hours with nothing running, A shows in the corner and does not take the keyboard. | 12, 13 | 17b, 17d | Engine + view test |
| G5 | Text + Enter starts an activity with the default category, length, ask offset, and calendar setting. | 17 | 17d | View test |
| G6 | A row of the Recent dropdown fills the text and category of that activity. | 17 | 17d | View test |
| G7 | C shows first at the earlier of start + askEvery and start + expected length + ask offset. For an Open activity, C shows every askEvery. A change of Ask every applies at once. | 14 | 17b | Engine test |
| G8 | Yes, 15 min more / 5 min / 30 min set the next ask time to now + that time. | 15 | 17b | Engine test |
| G9 | Skip changes no data and asks again after askEvery. | 15 | 17b | Engine test |
| G10 | No tracker prompt closes by itself. Only note F closes, after 1 min. | 12, 44 | 17b | Engine test |
| G11 | An answer 5 min or more late shows the late C with the waited minutes. | 16 | 17b | Engine test |
| G12 | Done opens A at once with the Started row: 5-minute chips from the last answer to now, Now selected, the grid when there are more than 4 chips. | 13a | 17b, 17d | Engine + view test |
| G13 | The picked switch time ends the old activity and starts the new one at the same second. | 13a | 17b | Engine test |
| G14 | The shortcut opens B from any app. Enter switches at that exact time. | 12, 17 | 17c, 17d | Manual |
| G15 | A tracker prompt sits below buddy popups in the corner column. | 19 | 17d | View test |
| G16 | 1 soft sound plays when A or C shows, and none when sound is off. | 20 | 17d | Engine test |
| G17 | Only 1 activity runs. A new one ends the old one at that moment. | 1 | 17b | Engine test |
| G18 | An activity shorter than 60 s is not saved. | 5 | 17b | Engine test |
| G19 | Away ends the activity at the earlier of the Away start and its confirmed-until time. The rest is Not logged. | 22 | 17b | Engine test |
| G20 | An activity never crosses midnight. | 27 | 17b | Engine test |
| G21 | After tracker hours a running activity continues and C still asks. No new A shows. | 25 | 17b | Engine test |
| G22 | Lock, sleep, and a closed lid start Away at that moment. 30 min idle starts Away at the last input. | 21 | 17b, 17c | Engine test + manual |
| G23 | D shows on return inside tracker hours. I was here shows only after an idle Away and puts the activity back. | 18 | 17b, 17d | Engine + view test |
| G24 | Take a break ends the activity. The break is Away · Break. D shows after the break. | 10 | 17b | Engine test |
| G25 | Idle detection uses a deadline, never a repeating timer. | Perf | 17c | Code review + perf |
| G26 | Add to calendar is off by default. The menu lists writable calendars by account, like time blocks. | 28 | 17d, 17e | View test |
| G27 | When an activity with a calendar ends, Sathi saves 1 event with the real start and end and keeps the event ID. | 29 | 17e | Spy test + 1 real event |
| G28 | A report edit updates the event. A delete deletes it. A missing event changes only the log. | 30 | 17e | Spy test |
| G29 | A calendar failure never blocks the tracker. The row shows Not in calendar and Save. | 31 | 17e | Spy test |
| G30 | Calendar reading is off by default. Sathi reads only the ticked calendars. | 42 | 17j | Spy test |
| G31 | Sathi skips all-day, declined, and Sathi-written events. Free events count. | 43 | 17j | Spy test |
| G32 | Log and tell: at the event start the activity switches, note F shows for 1 min, and no C asks before the event end. | 44 | 17j | Engine test |
| G33 | Ask first: the prompt stays. Yes logs from the event start, also when late. | 45 | 17j | Engine test |
| G34 | Mac away during an event: Sathi logs it with no question and shows it in D. | 46 | 17j | Engine test |
| G35 | A running event that is not logged is the first chip in A and B. | 47 | 17j | View test |
| G36 | Category order: the pick for that event name, then the calendar's category, then the calendar name. | 48 | 17j | Engine test |
| G37 | Sathi never writes an event for an event activity. No event is logged 2 times. | 49 | 17j | Spy test |
| G38 | 2 events overlap: the first stays, and a note offers Switch. | 50 | 17j | Engine test |
| G39 | The Activities tab opens any past day from the arrows or the calendar. Days with activities show a dot. | 33 | 17f | View test |
| G40 | Real work + Away + Not logged = the tracked span of the day. | 6, 33 | 17f | Unit test |
| G41 | Edit, Fill, and Add past activity work and refuse an overlap. | 33 | 17f | Engine + view test |
| G42 | Copy for standup gives the text of rule 35. | 35 | 17f | Unit test |
| G43 | The Month view lists each day, a row opens that day, and Copy monthly report gives the text of rule 36. | 34, 36 | 17f | Unit + view test |
| G44 | Export month writes JSON and CSV to Downloads and shows it in Finder, with no save panel. | 34 | 17f | Manual |
| G45 | The end-of-day popup shows 1 time a day, at the end of hours or after the last activity. The animation is 1.5 s at most and none with Reduce motion. | 26 | 17g | Engine test + perf |
| G46 | The settings page has every row of rule 39. A change applies at the next ask. | 39 | 17h | View test |
| G47 | Categories: add, rename, delete. A deleted category stays on old activities. | 40 | 17h | Unit test |
| G48 | The menu shows the running activity with Done, and Log activity opens B. | 41 | 17h | View test |
| G49 | activities/YYYY-MM.json is written atomically with whole seconds and kept forever. An unreadable item is dropped and the others stay. Unknown fields are kept. | Storage | 17a | Unit test |
| G50 | Old prefs.json and state.json without tracker keys load the defaults. | Storage | 17a | Fixture test |
| G51 | The running activity and the open prompt survive a restart. | Storage | 17a, 17b | Engine test |
| G52 | The JSON backup includes the activity months. | Storage | 17a | Unit test |
| G53 | With the tracker on: idle CPU under 1%, memory in budget, under 10 wakeups a minute. | Perf | 17d, 17g | perf.sh |
| G54 | No repeating timer. Every wait comes from upcomingDeadlines(). | Perf | 17b | Code review |
| G55 | Tests, lint, and the release build pass. No file over 200 lines. No comments. | DoD | all | test.sh, lint.sh |
| G56 | The time block page and the website no longer say "It never reads your events". | 42 | 17i, 17j | Manual |

| G57 | A reading, breathing, or gym session start ends the running activity and starts a buddy activity with the buddy category. | 53 | 17k | Engine test |
| G58 | No tracker prompt asks while a buddy session runs, also while a breathing session is paused. | 54 | 17k | Engine test |
| G59 | When a session ends, A opens at once with "Continue {last activity}" and the Started row. Sathi never continues the old activity without an answer. | 55 | 17k | Engine + view test |
| G60 | A water glass and a quick reminder make no activity. A buddy activity writes no calendar event. | 56, 57 | 17k | Engine test |
| G61 | A always shows For, Add to calendar with its menu, and No popups until it ends. | 17 | 17d | View test |
| G62 | Quiet time: no tracker prompt and no buddy popup until the expected end. Buddy reminders wait and then show. Quick reminders still show. Events are still logged. | 58, 59 | 17l | Engine test |
| G63 | The shortcut, the menu, or Done ends quiet time at once. The menu bar shows "Quiet until {time}". | 58, 60 | 17l | Engine + view test |
| G64 | When a prompt shows, the keyboard stays in the app that had it. | 62 | 17d | Manual |
| G65 | An event start beats a C ask at the same moment. A full-screen lock shows before a tracker prompt. | 63, 64 | 17l | Engine test |

## Storage

- New files `activities/YYYY-MM.json`: `schemaVersion`, `value` (the item list, storage rule 2): `id`, `kind` (`work`, `away`, `timeBlock`, `event`, `buddy`), `text`, `category?`, `start`, `end`, `awayPlace?`, `calendarID?`, `eventID?`, `sourceEventID?`. Whole seconds. Kept forever. An unreadable item is dropped and the others stay. Unknown fields and kinds are kept and written back (History rule 8).
- `LiveState.tracker` in `state.json`: the running activity (`id`, `text`, `category?`, `start`, `expectedLength?`, `askAt`, `calendarID?`, `quietUntil?`), the open prompt (`kind`, `shownAt`, `askTime`), `awaySince?`, `lastInput?`, `lastEndOfDay?`. A missing key loads an empty tracker.
- `Prefs.tracker: TrackerPrefs`: `isOn` (false), `startMinutes` (540), `endMinutes` (1080), `weekdays` (Mon–Fri), `daysOff`, `askEveryMinutes` (15), `usualLength` (30), `idleMinutes` (30), `categories` (Coding, Meeting, Cefalo Meetings, Review, Learning, Email, each with a color), `calendarOnByDefault` (false), `defaultCalendarID?`, `shortcut` (⌃⌥⌘Space), `endOfDayOn` (true), `playsSound` (true), `readsEvents` (false), `quietByDefault` (false), `readCalendarIDs` ([]), `eventMode` (`.logAndTell`), `categoryByCalendar` ([:], a missing calendar uses its own name), `eventCategoryByTitle` ([:]). Lenient decoding: a missing or unknown value loads the default.
- The full JSON backup includes the activity months.
- No schema bump. Fixture tests load an old `prefs.json` and `state.json` without these keys. Follow `.claude/rules/storage.md` and `/data-migration`.

## Ports

- `PresenceMonitor` (new): events `locked`, `unlocked`, `sleep`, `wake`, and `secondsSinceLastInput()`. Production uses workspace and distributed notifications and `CGEventSource`. No polling: the Engine adds `lastInput + idleMinutes` to `upcomingDeadlines()` and reads the idle seconds only at that deadline.
- `HotkeyRegistrar` (new): registers 1 global shortcut and calls the Engine. Production uses the Carbon `RegisterEventHotKey` API (part of macOS, no new dependency, no Accessibility permission).
- `CalendarWriter` (phase 13): add `delete(eventID:)` and `events(from:to:calendarIDs:) -> [CalendarEventInfo]` (`id`, `title`, `start`, `end`, `calendarID`, `isAllDay`, `declined`).
- `ActivityStore` (new): load and save a month of activities. Production `FileActivityStore`; test `InMemoryActivityStore`.

## Performance

No repeating timer. `upcomingDeadlines()` adds the next ask time, the next A time, the idle deadline, the end of tracker hours, and midnight. The end-of-day animation runs only while the popup is visible and ends in 1.5 s. Run `/perf-check` after 17d and 17g.

## Slices

| Slice | Content | Check |
|---|---|---|
| 17a Core data | Rules in `business-logic.md`, `Activity`, `TrackerPrefs`, `LiveState.tracker`, `ActivityStore` port, file store, decoding fixtures, backup | `./scripts/test.sh`, lint |
| 17b Engine flow | Rules 8–27 with `FakeClock`: asks, late answers, Skip, Away, idle, break, time block, hours end, midnight, end of day | Engine tests for each row of the Flow tab |
| 17c Platform | `PresenceMonitor`, `HotkeyRegistrar`, `CalendarWriter.delete`, `AppEnvironment` | User tests lock, sleep, idle, and the shortcut |
| 17d Prompts UI | Prompts A–D, corner column order, sound | ViewInspector tests, `/perf-check` |
| 17e Calendar | Save on end, update on edit, delete, "Not in calendar" | `SpyCalendarWriter` tests, 1 real event |
| 17f Reports | Activities tab: Day, Month, date picker, edit, Fill, add past, copy texts, export | ViewInspector tests, `--windows` |
| 17g End of day | Popup with timeline animation | `/perf-check` |
| 17h Settings and menu | Settings page, "My day" group, menu row and "Log activity" | ViewInspector tests |
| 17j Calendar events | Rules 42–52: read, log and tell, ask first, while away, chip, category memory, overlaps, note F, settings rows | `SpyCalendarWriter` tests, then 1 real Gmail meeting |
| 17k Buddy sessions | Rules 53–57: session start and end, auto-return note | Engine tests with each buddy |
| 17l Quiet time and conflicts | Rules 58–64 and the visible A rows of rule 17 | Engine and view tests |
| 17i Docs | `CLAUDE.md`, `README.md`, `ROADMAP.md`, website | Full Definition of done |

## Later (tracker phase 2)

- Week view.
- Remove time blocks and move their data (ADR 0001).
- Edit many items at once (split, merge).
