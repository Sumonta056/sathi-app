# Phase 18: Main window, quick panel, one activity prompt, stats ranges

Sathi gets one normal macOS window with a sidebar: Today, Activities, Reports, and Settings. The menu bar panel becomes a short quick panel. The 5 tracker prompts become 1 activity prompt at the screen center. Reports and Activities get a Day / Week / Month range with ‹ › and a compare with the range before.

Branch: `feat/app-window` (worktree `../Sathi-app-window`). Plan: `docs/superpowers/plans/phase-18-app-window.md`.
Design (HTML mockups, Night palette, Figtree): `docs/design/phase-18/` — `Main.dc.html` (Today), `Activities.dc.html`, `Reports.dc.html`, `Settings.dc.html`, `QuickPanel.dc.html`, `ActivityPrompt.dc.html` (its `<script>` holds the per-reason tags, colors, icons, and texts). Match their layout, spacing, sizes, and colors.
Terms: `GLOSSARY.md` (Main window, Quick panel, Range, Activity prompt).

## Why

Settings and Reports are 2 separate windows, and the menu panel holds a long list of cards. The user cannot see the day at a glance. The tracker has 5 prompts in 2 places (corner and center) with different layouts, so the user must learn 5 forms. One window, one short panel, and one prompt make Sathi easier to learn and faster to use.

## Out of scope

- Buddy reminders do not change: bubble, corner popup, lock, snooze, and escalation stay as they are.
- Quick reminder popups and the 10 PM day summary popup do not change.
- No new saved data. No schema change. No new tracker business rule, except the presentation rules below (rules 30–52).
- Time blocks stay. Their Settings page moves into the main window.

## Rules

### Main window

1. Sathi has 1 main window. It is a normal titled macOS window (`.titled`, `.closable`, `.miniaturizable`, `.resizable`, full-size content), Night palette, dark appearance. Default size `UIMetrics.mainWindowSize` (1200 × 760 pt, from the mockups). Minimum size `UIMetrics.mainWindowMinSize`.
2. Left sidebar, top to bottom: the Sathi logo and name, then 4 pages: Today, Activities, Reports, Settings. Below them, a status block: "TRACKER ON" + "{start} – {end} · asks every {n} min" when the tracker is on, else "TRACKER OFF".
3. When Settings is the selected page, its sub-pages show nested below "Settings" in the sidebar, in this order: General, Fota, Boi, Shanti, Shokti, Quick reminders, Activity tracker, Time blocks, Sound. The first open of Settings selects General.
4. The Settings window and the Reports window are removed. Their content moves into pages of the main window. Every path that opened them now opens the main window on that page:

| Old path | New page |
|---|---|
| Menu footer "Settings", any "open settings" | Settings → General |
| Menu footer "Reports", "Open reports" sidebar row | Reports |
| End-of-day "Open full report" (`openActivityReport(day)`) | Activities, Day range, that day |
| Time block "Open settings" / calendar settings links | Settings → Time blocks |
| Tracker menu card and tracker prompt links to settings | Settings → Activity tracker |

5. The main window opens on a page with `Engine.openMain(_ page: MainPage)`. When it is already open, it comes to the front and changes to that page. Sathi activates itself, so the window takes the keyboard.
6. Dock icon: Sathi uses activation policy `.regular` (Dock icon, app menu) only while the main window is open. When the main window closes, Sathi goes back to `.accessory` (menu bar only). `LSUIElement` stays `true` in `Info.plist`.
7. Launch: a launch by the user (Finder, Spotlight, `open`, Dock) opens the main window on Today. A launch as a login item opens nothing; Sathi starts in the menu bar only. A second launch while Sathi runs (`applicationShouldHandleReopen`) opens the main window on Today.
8. Close (the red button or ⌘W) closes the main window. Sathi keeps running in the menu bar. The window content is freed (`contentView = nil`, reference dropped), like the old windows, so memory goes back into budget. ⌘Q quits Sathi (app menu "Quit Sathi").
9. Page state is not saved. Each open of the main window starts on the asked page with the current range.

### Today page (`Main.dc.html`)

10. Header: the date in uppercase ("TUESDAY, 11 NOVEMBER") and the greeting (`Engine.greeting`, "Good afternoon"). On the right: "Quick reminder" (opens the quick add popup) and "Take a break" (the existing break menu).
11. Now card, when the tracker is on and an activity runs: big minutes so far ("42m", `Fmt` length), "NOW", the activity text, and "{category} · since {start} · Still on it? at {next ask}" (the next ask part only when known). Buttons: "Switch" (opens the activity prompt with reason shortcut, like the shortcut) and "Stop" (calls `doneActivity()`, rule 39). When the tracker is on and nothing runs: "Not tracking now", "Next ask {time}" when known, and "Log activity". When the tracker is off: the card shows "Activity tracker is off" and "Turn on" (opens Settings → Activity tracker).
12. Buddy cards: 1 card for each of the 4 buddies, in `HabitID.allCases` order. Each card: buddy name and habit, today's total and goal ("5 / 8 glasses", "20 / 20 min"), a progress bar, and 1 status line: "✓ Goal met", "Day off", "Off", "No reminder", or "Next at {time}". Shokti shows "Session {n} of {sessionsPerDay} at {time}". Shanti adds a "Breathe now" link that starts a breathing session. The words and states follow the menu card rules (Stats rules 12, 13; Habits rule 12).
13. "Today so far": a timeline strip of tracker hours with the day's segments (work by category color, Away, Not logged), the hour labels, "{length} logged", and up to `Limits.todayCategoryRows` (4) category totals, longest first. With the tracker off, the section shows "Turn on the activity tracker to see your day." Data: `ActivityTimeline.segments` and `ActivityDayStats` of today.
14. "Coming up": today's next items in time order, at most `Limits.comingUpMax` (6): the next tracker ask ("Still on it?" or "What now?", from `trackerNextPopup`), the next due time of each enabled buddy that is not met, off, or on a day off ("Fota · water"), each pending quick reminder due today (its text), and the day summary when it is on and has not shown today ("Day summary"). Items before now and items after today are left out. An empty list shows "Nothing more today."
15. Updates: the Today page changes at most 1 time per minute, plus at once on a real data change (a glass, an activity start, a settings change). It uses a `TodayModel` that publishes only when the built `TodayScreen` value changes, and the screen holds only minute-resolution values. No timer of its own. During a running breathing session (1 s engine ticks) the Today page does not redraw each second.

### Quick panel (`QuickPanel.dc.html`)

16. The menu bar panel becomes the quick panel. Width `UIMetrics.quickPanelWidth` (from the mockup, 360 pt incl. padding). Top to bottom:
    1. Header: "Sathi" and the short day and time ("Tue 14:52").
    2. When the tracker is on: a Now row, "NOW · {minutes}" and the activity text, with "Switch" (opens the activity prompt, reason shortcut). With nothing running: "Not tracking now" and "Log activity".
    3. The 4 buddies as compact rows: color dot, buddy name, and a status ("5 / 8", "✓ Goal met", "{next time}", "10 / 20 min", "Off", "Day off"). Fota has a "+1 glass" button (logs 1 glass, the same action as the old water card).
    4. "Quick reminder" and "Take a break" buttons. The pause banner (`NapBanner`) shows above the buddies while Sathi is paused.
    5. A big "Open Sathi" button (main window, Today).
    6. Links: "Reports" (main window, Reports), "Settings" (main window, Settings → General), "Quit".
17. While a time block runs or waits for a calendar, the quick panel keeps the existing `TimeBlockCard` below the Now row, so a running block stays visible and can end. The "Time block" start button stays in the quick panel action row next to "Quick reminder" and "Take a break". (Open question Q1.)
18. Removed from the menu panel: the big habit cards (`HabitList`, `HabitCard`), `SleepingRow`, `QuickListCard` (moves to Settings → Quick reminders), `ToolRow`, `MenuHeader` streak, and the old footer. Their logic stays in the Engine where other pages use it. View files with no user are deleted with their tests; each removed test is named in the commit message with the reason.
19. The quick panel opens on a click of the menu bar icon, as now. It closes when the user picks "Open Sathi", "Reports", or "Settings".

### Settings pages (`Settings.dc.html`)

20. Each settings page has a header: "SETTINGS" eyebrow, the page title ("Fota · water"), and, on a buddy page, an "On" switch for that buddy (moved from the sidebar). The content is the existing tab content, in the existing cards.
21. General: name, look and feel, reminders (snooze, snoozes allowed, ignore), day summary, behaviour (open at login, quiet in meetings). The "Quick reminders" card and the "Play soft sounds" switch move out.
22. Quick reminders (new page): the existing `QuickSettingsCard` (level, close button) and the list of pending quick reminders with Delete (the old `QuickListCard` rows) and "+ Quick reminder".
23. Sound (new page): "Play soft sounds" (General sound) and the breathing session sound card (`MeditationSoundCard`: voice, music, bell, minute tick, Preview). The Shanti page links to it with "Session sound is on the Sound page."
24. Activity tracker and Time blocks: the existing pages, unchanged.
25. "Add a buddy" (coming-soon cards) is removed from the sidebar, because the mockup has no place for it. (Open question Q2.)
26. A footer line on every settings page: "Settings save at once."

### Ranges (Reports and Activities)

27. A range is Day, Week, or Month (`ReportRange`), with a start and an end (`StatsRange`). Day: 00:00 to the next 00:00. Week: 7 days from the first weekday of the user's region (`Calendar.current.firstWeekday`) on the Gregorian calendar of the user's time zone. Month: the calendar month. This replaces "Week: Monday to Sunday" (Stats rule 3) for Reports and Activities. Other places that use `Limits.weekStartWeekday` (the days-off month picker, the streak calendar) do not change.
28. Each page has a segment control Day / Week / Month and ‹ › arrows with the range title between them: Day "Today, 11 Nov" / "Yesterday, 10 Nov" / "Mon, 3 Nov"; Week "3 – 9 Nov" (or "27 Oct – 2 Nov" across months); Month "November 2026". ‹ moves 1 range back, with no limit. › moves 1 range forward and is off on the range that holds today. A change of the range kind keeps the day: the new range holds the first day of the old range, or today when the old range holds today.
29. Compare: every total shows a change against the range before. For a past range, the whole previous range counts. For the range that holds now, the previous range is cut at the same point: the same number of whole days from its start, plus the same clock time as now (Tue 14:52 this week compares with Mon 00:00 – Tue 14:52 last week). A cut end never passes the previous range end. Words: "+6 vs last week", "−1 vs last week", "same as last week"; "yesterday" for Day, "last month" for Month. Lengths use `Fmt` ("+40m", "−2h 05m"). With no data in both ranges, the change line is hidden.

### Reports page (`Reports.dc.html`)

30. Header: "Reports", the range control (rule 28), and "Export CSV".
31. Buddy totals: 4 cards in `HabitID.allCases` order. Each card: "{buddy} · {habit}", the total of the range in the goal unit (Water glasses; Reading, Meditation, and Gym minutes, shown as a length), the change line (rule 29), and "goal met {m} of {n} days". The days count with Stats rule 4 (days up to today only, days off left out unless met). A buddy that is off shows a dimmed card with "Off" (Stats rule 8); its history stays in the totals.
32. "Goals met per day": 1 bar for each day of the range (Day: 1 bar), height = buddies with the goal met that day, out of the buddies that are on and not on a day off that day ("of 4 buddies" label uses that count for today). Future days show an empty bar.
33. "Time by category": activity time of the range by category, longest first, with the change vs the range before ("vs last week"). Calendar-event activities form 1 row "Calendar events", and Away forms 1 row "Away". With the tracker never used, the card shows "No activities in this range."
34. A tap on a buddy card selects it and shows its detail below the cards: the existing chart, streak calendar, and facts (`HabitReportsView` parts) for the shown range. A second tap hides the detail. Reports rules 9–11 stay.
35. Export CSV: writes the history events of the shown range as CSV (`CSVExporter`) to `~/Downloads` with a free file name and shows it in Finder. No save panel (`performance.md`). A failed write shows "Could not save the file." This brings back export for Reports (Stats rule 7 changes).

### Activities page (`Activities.dc.html`)

36. Header: "Activities", the range control (rule 28), and "Export".
37. Day: the activity log of that day (existing rows with Edit, Fill, Delete, and "+ Add past activity"), the Totals card by category, and the "Standup text" card with "Copy" (rule 35 of phase 17). The running activity row shows "{start} – now".
38. Week and Month: 4 tiles (Real work, Average day, Best day, Away) with the change vs the range before, 1 row for each day of the range with a small timeline strip (a click opens that day in the Day range), totals by category with change, and a "Copy" card with the range text: the monthly report text of phase 17 rule 36, with the range title in place of the month.
39. Export: the activities of the shown range as CSV (the `ActivityMonthExporter.csv` columns) to `~/Downloads`, shown in Finder, no save panel. File name `sathi-activities-{start}-{end}.csv` (day keys).
40. With the tracker off and no activities in the range, the page shows "The activity tracker is off." and "Turn on" (Settings → Activity tracker).

### Activity prompt (`ActivityPrompt.dc.html`)

41. The 5 tracker prompts (`PromptKind`: `whatNow`, `center`, `stillOnIt`, `welcomeBack`, `eventAsk`) become 1 activity prompt. `PromptKind` and its raw values stay (they are saved in `state.json`). Each kind maps to 1 reason:

| `PromptKind` | Reason | Color | Tag | Time text |
|---|---|---|---|---|
| `whatNow` | ask | coral `#FF8A80` | "TIME TO CHECK" | the ask time |
| `center` | shortcut | violet `#A99CF5` | "YOU ASKED · {shortcut}" | now |
| `stillOnIt` | ends | amber `#FFC94A` | "ACTIVITY ENDED" when now is at or after the expected end, else "STILL ON IT?" | "{start} – {expected end}", or "{start} – now" for Open |
| `welcomeBack` | back | green `#5FD39A` | "WELCOME BACK" | "AWAY {start} – {end}" |
| `eventAsk` | event | blue `#7FB8FF` | "CALENDAR EVENT" | "{event start} – {event end}" |

42. Place: the prompt is a floating panel at the center of the display that has the mouse pointer when it first shows. It never shows in the corner column. Size from the mockup: `UIMetrics.activityPromptWidth` (880 pt); height fits the content (no empty space).
43. Only 1 activity prompt shows at a time. A new reason replaces the content of the open panel in place; Sathi never opens a second prompt panel. The panel keeps its place and its keyboard state when the content changes.
44. The prompt stays until Start, Keep going, or Skip (✕ is Skip). None goes away by itself (phase 17 G10 stays).
45. Keyboard: the prompt never takes the keyboard when it shows, so typing in another app goes on there. Only when the user opened it (the shortcut, "Switch" or "Log activity" in the quick panel or the Today page, or "Stop" → the switch form; `trackerPromptByUser`) does it take the keyboard at once. A click in the prompt gives it the keyboard. When the prompt closes after it took the keyboard, the keyboard goes back to the app that had it.
46. Header (full width, `Night.promptHeader` `#161D2C`, a 4 pt top bar in the reason color): an icon tile in the reason color (icons per reason from the mockup: clock, keyboard, flag, door, calendar), the tag and the time in monospace, the title, and 1 message line. ✕ on the right is Skip. Titles: "What are you doing now?"; shortcut while an activity runs: "Switch to something new?"; event: "Log “{title}” now?". Message lines:
    - ask: "Nothing is running. {last text} ended at {time}." or "Nothing is running." with no last activity. After a buddy session: "{session} ended at {time}."
    - shortcut: "Now: {text} · {n} min since {start}. Switch ends it." or "Nothing is running."
    - ends: "{text} · {n} min so far as {category}." Late (phase 17 rule 16): "This question waited {n} min."
    - back: "{text} stopped at {time} when the Mac went to sleep." (by `AwayCause`: `asleep` "went to sleep", `locked` "was locked", `idle` "was idle", `onBreak` "you took a break"). With no running activity before Away: "You were away {n} min."
    - event: "{title} is in your {calendar} calendar. It ends by itself at {end}."
47. Welcome back adds "Where were you?" boxes inside the header: the built-in places of `AwayPlace.choices` in their order (Lunch, Meeting, Walk, Commute, Other; the mockup's "Break" and "Gym" boxes are not added, because a break is set by Take a break and gym by a buddy session), 1 box for each user-made place, and "+ Place" (opens a text field; phase 17 rule 18 limits). A pick is saved at once (`pickPlace`, `pickPlaceName`, `addPlace`). The picked box is filled green. While-away event rows (phase 17 rule 46) show below the boxes with "Not attending".
48. Body, left pane "RECENT · tap to fill": the recent activities as row cards (category color bar, name, "{category} · last {length}", and the key "⌘1" … "⌘6"). It shows `Limits.recentShown` (6) rows and a "Show all {n}" link that shows up to `Limits.recentMax` (10). A tap or ⌘1–⌘6 fills the text and category; it does not start (this replaces "a pick starts at once"). The filled card has the accent border. A running calendar event that is not logged is the first card (phase 17 rule 47).
49. Body, right pane: the text field ("Type what you do, or tap a card on the left"; accent border when the prompt has the keyboard), then 5 rows. Every choice is a square box with 6 pt corners (`UIMetrics.promptBoxRadius`), never a dropdown and never a round pill:
    - Category: all categories as boxes with their color dot. A tap on the selected box clears it (no category).
    - For: 15 min, 30 min, 1 h, Open (`Limits.activityLengths` + Open). Event: "Until {end}" only.
    - Ask me: When it ends, +5 min, +15 min (`Limits.askOffsets`).
    - Calendar: all writable calendars as boxes and "None". The picked box is filled with its calendar color. A line below says what will happen: "One event goes to {calendar} when the activity ends." / "Sathi adds no event for this activity." Access states keep phase 17 rule 12 (business rule 12): not asked → an "Allow calendar access" box; denied → "Open System Settings"; no writable calendar → dim "No calendars found on this Mac." Event reason: the row is read-only and says "Already in your {calendar} calendar, so Sathi adds no copy." (phase 17 rule 49).
    - Quiet: the "No popups until it ends" switch. Off and disabled for Open.
    - Event reason: no Ask me row and no Quiet row, and the text field is fixed to the event title, because Log it uses only the category.
50. Started: the bottom left shows a small link "Started: {Now | time} · change" and "Esc: Skip". A tap opens a row "It really started at" with 5-minute boxes (`SwitchTimes.chips`) from a reason-specific time up to now, Now selected by default. From-time per reason: ask after Done → the last answer (phase 17 rule 13a); ends → the running activity's last answer (or start); back → the Away end; shortcut while running → the running activity's last answer; ask with no switch and shortcut with nothing running → only Now (the link is hidden). Event: no link; the event start is fixed (phase 17 rule 45).
51. Footer: Skip (outline) and Start. Esc = Skip, when the prompt has the keyboard.

51a. Running card (design A, 2026-11-12). Every reason that has a Keep action (rule 52) shows a card at the top of the right pane, above the text field, with a border in the reason color. Below the card a line says "or switch to something new". The card holds:
    - a tag: ends and shortcut "NOW RUNNING"; back "BEFORE YOU LEFT"; ask after a buddy session "LAST ACTIVITY";
    - the activity name, its category with its color dot, and a detail line: running "Started {time} · {n} of {length} min", past the length "Started {time} · {n} min · {over} min over" (Open: "Started {time} · {n} min so far"); back: "{text} stopped at {time} …" when Away stopped it, else no detail line; ask: "{session} ended at {time}.";
    - a progress bar for a running activity with a length (elapsed ÷ length, at most 1), fixed when the prompt shows (no timer);
    - the Keep button (rule 52 label), filled in the reason color.
    With a card: the ends title is "Still on {text}?"; the back title is "Welcome back. Where were you?"; the header message is short: ends "{n} min so far. Keep going, or switch." (late keeps "This question waited {n} min."), shortcut "Keep it, or type a new one to switch.", back "You were away {n} min.", ask "Continue it, or start something new.". The text field has no accent border while it is empty.
    Start is an outline while the text is empty and a card shows; it fills in the reason color when the text has a name (typed or from a recent card). Enter: empty text and a card → Keep; else Start. Without a card (ask with nothing to continue, event), Start is always filled and Enter = Start.

52. Action mapping. Every old action keeps its Engine call; only the button that calls it changes. The Keep going column is the button in the running card (rule 51a):

| Reason | Start (label) | Keep going (label) | Skip |
|---|---|---|---|
| ask | `startActivity(draft, switchAt:)` ("Start") | after a buddy session only: `continueActivity(switchAt:)` ("Continue {text}") | `skipTrackerPrompt(switchAt:)` (after Done it ends the old activity at the picked time, as now) |
| shortcut | `startActivity(draft, switchAt:)` ("Switch" while running, else "Start") | while running: `closeTrackerPrompt()` ("Keep {text}") | `closeTrackerPrompt()` |
| ends | `startActivity(draft, switchAt:)` ("Switch"), which ends the old activity at the picked Started time (replaces "Done · pick when you switched" + A) | `stillOnIt(minutes: askEvery)` ("Keep going +{askEvery} min"); late: `stillOnItLate()` ("Still on it") | `skipTrackerPrompt()` (no data change, asks again after Ask every) |
| back | `startActivity(draft, switchAt:)` ("Start") | when a last activity exists: `backToLastActivity()` ("Back to {text}"); after an idle Away also "I was here" link in the header (`iWasHere()`) | `closeTrackerPrompt()` (keeps the Away, like Esc before) |
| event | `pickEventCategory(category)` then `answerEvent(true)` ("Log it") | — | `answerEvent(false)` ("Skip" = No) |

    Dropped buttons, because the layout covers them: C "Or more 5 min / 30 min" (Keep going uses Ask every; the user changes the next ask with Ask me on a new start), C "Done", D "Something new" (the form is always visible). The menu's "Done" (`doneActivity()`) stays and opens the prompt with reason ask and the Started link from the last answer.

### Notes and the end-of-day popup

53. Note F (calendar event logged, "Also now" note) shows at the screen center of the mouse display, not in the corner. It keeps its content, its 1-minute auto close, and it never takes the keyboard. When the activity prompt is open, the note sits above the prompt with a gap of `UIMetrics.centerStackGap`; with no room above, below it.
54. The end-of-day popup shows at the screen center of the mouse display (as now), never takes the keyboard, and keeps its content. When the activity prompt is open at the time it is due, it waits and shows right after the prompt closes (Engine, still 1 time a day).

### Performance

55. No new repeating timer. The Today page and the quick panel read minute-resolution values. Every view with an animation pauses when hidden. With the main window closed, idle CPU < 1%, < 10 wakeups a minute. After the main window opens and closes: memory < 50 MB, and a second open/close cycle adds < 3 MB (`perf.sh --windows`, the user runs it with the main window in place of Settings and Reports).

## Acceptance criteria

| ID | Goal | Rules | Check |
|---|---|---|---|
| W1 | Every old "open settings" and "open reports" path opens the main window on the right page. No Settings or Reports window type remains. | 4, 5 | Engine spy test + grep |
| W2 | The Dock icon shows only while the main window is open. | 6 | Unit test of the policy function + manual |
| W3 | A user launch opens Today. A login-item launch opens nothing. A reopen opens Today. | 7 | Unit test of the launch decision + manual |
| W4 | Close keeps Sathi in the menu bar and frees the window. ⌘Q quits. | 8 | Manual + `perf.sh --windows` |
| W5 | The sidebar lists Today, Activities, Reports, Settings, and nests the 9 settings pages under Settings. | 2, 3 | View test |
| T1 | Today shows the Now card, 4 buddy cards, Today so far, and Coming up with the right states. | 10–14 | View + unit tests |
| T2 | Coming up is sorted, today only, max 6, and leaves out met, off, and day-off buddies. | 14 | Unit test |
| T3 | `TodayModel` publishes at most 1 time per minute with no data change, also during a breathing session. | 15 | Engine test with `FakeClock` |
| Q1 | The quick panel shows the Now row, 4 compact buddy rows, +1 glass, the action buttons, Open Sathi, and the 3 links. | 16 | View test |
| Q2 | +1 glass logs 1 glass. Open Sathi, Reports, and Settings open the main window on that page. | 16 | View test with the spy presenter |
| S1 | Quick reminders and Sound are their own pages with the moved cards; General no longer holds them. | 21–23 | View test |
| R1 | Day / Week / Month and ‹ › give the right intervals; › is off on the range that holds today. | 27, 28 | Unit test |
| R2 | Week start follows `firstWeekday` (Sunday and Monday regions). | 27 | Unit test |
| R3 | The current range compares with the previous range cut at the same point. | 29 | Unit test |
| R4 | Buddy totals, days met, and goals-met-per-day bars are right, with days off. | 31, 32 | Unit test |
| R5 | Time by category with change vs the range before. | 33 | Unit test |
| R6 | Export CSV of Reports and Export of Activities write to Downloads with no save panel. | 35, 39 | Engine test with a temp folder + manual |
| A1 | Activities Week and Month show tiles, day rows, category totals, and the range text. | 38 | Unit + view test |
| P1 | Each `PromptKind` shows the reason tag, color, title, message, and the buttons of rule 52. | 41, 46, 52 | Unit test of `ActivityPromptScreen` + view test |
| P2 | Every choice is a square box; no `Menu` or dropdown in the prompt. | 49 | View test |
| P3 | A recent card tap and ⌘1–⌘6 fill text and category and do not start. | 48 | View test |
| P4 | Only 1 prompt panel; a new reason replaces its content in place. | 43 | UI controller test with a spy panel factory + manual |
| P5 | The prompt takes the keyboard only when the user opened it. | 45 | Unit test of the keyboard rule + manual |
| P6 | Started shows the reason's 5-minute boxes; the pick ends the old activity and starts the new one at that second. | 50 | Engine test |
| P7 | Every old prompt action still works through the mapping table (rule 52). Existing tracker engine tests pass unchanged. | 52 | `./scripts/test.sh` |
| N1 | Note F and the end-of-day popup show at the screen center; end of day waits for an open prompt. | 53, 54 | Engine test + manual |
| D1 | Tests, lint, release build pass. No file over 200 lines. No comments. Perf budget holds. | DoD | scripts |

## Edge cases

- The main window is open on Reports while a day passes: the range that held today moves on only when the user taps or reopens; › turns on for the old range. The Today page moves to the new day at the first minute tick.
- A month with 31 days compared with a month of 30: the cut end stops at the previous range end (rule 29).
- A week that crosses a DST change has 7 calendar days; lengths come from real times, days from `Calendar.startOfDay`.
- A range before the oldest history month loads no events and shows zeros with no change line.
- Ranges older than `Limits.monthsInMemory` load their months on demand and drop them after the build (History rule 3).
- The user changes the tracker reason while typing (for example, an event starts while the shortcut prompt is open): the content changes in place; the typed text is lost only when the new reason has its own text (event). The keyboard stays where it was.
- The activity prompt is open and a full-screen lock shows: the lock covers it; the prompt stays and is there after the lock (phase 17 rule 64 is for new prompts only).
- The display with the mouse is removed while the prompt is open: the panel moves to the main display center at the next content change.
- Login-item detection fails on some macOS versions (the Apple event flag is missing for `SMAppService` items): Sathi then treats the launch as a user launch and opens Today. The manual test notes record what macOS 13 and 15+ do. (Open question Q3.)
- The main window is open when a buddy lock shows: the lock covers all screens as now.
- A launch by the user while the tracker prompt waits from `state.json`: the main window opens on Today and the prompt shows centered, without the keyboard.

## Storage

No change to `prefs.json`, `state.json`, `history/`, or `activities/`. `PromptKind` raw values stay. The main window page and ranges are not saved. No fixture change.

## Open questions (defaults used by the plan)

- Q1: Time blocks in the quick panel. Default: keep the running `TimeBlockCard` and the "Time block" start button (rule 17).
- Q2: "Add a buddy" coming-soon page. Default: removed from the sidebar (rule 25).
- Q3: Login-item detection. Default: `keyAELaunchedAsLogInItem` from the launch Apple event; if macOS does not set it, treat as a user launch.
- Q4: "Keep going +{n} min" uses `TrackerPrefs.askEveryMinutes` (the old "Yes, 15 min more"), not the Ask me offset.
