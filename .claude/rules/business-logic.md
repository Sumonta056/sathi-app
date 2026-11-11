---
paths:
  - "Sources/SathiCore/**/*.swift"
  - "Sources/SathiUI/**/*.swift"
  - "Tests/**/*.swift"
---

# Business logic rules

These rules define what Sathi does. Code and tests must agree with them. If a request conflicts with a rule, stop and ask the user. Change this file first, then the code.

## Words

| Word | Meaning |
|---|---|
| Habit | One thing Sathi reminds about. A case of `HabitID`. |
| Buddy | The character of a habit. Water = Fota, Reading = Boi, Meditation = Shanti, Gym = Shokti. |
| Module | All the code of one habit: `SathiCore/Habits/<Name>/` and `SathiUI/Features/<Name>/`. |
| Due | The time a reminder must show. Comes from the habit's `HabitRules.nextDue`. |
| Reminder | What the user sees when a habit is due: bubble, corner popup, or lock. |
| Snooze | The user delays a reminder. Not answering for `ignoreMinutes` also counts as a snooze, for every habit. A tap on the close button also counts as a snooze (Escalation rule 8). |
| Session | A timed activity: reading, meditation, or gym. `Activity.session(Session)` in `Engine.activities[id]`. A meditation session can be paused (`Session.pausedAt`). |
| Event | One record in history: done, snooze, or skip. `HistoryEvent`. |
| Goal | The daily target of a habit. Water: glasses. Reading and meditation: minutes. Gym: minutes, `sessionsPerDay` × `sessionMinutes` (a done session counts its real minutes; a gym done event saved before `LiveState.gymMinutesSince` counts `Limits.gymLegacyDoneMinutes`). |
| Streak | Count of days in a row, up to today, on which the goal was met. A day off with the goal met adds 1. A day off without the goal met is skipped: it neither breaks the streak nor adds to it. |
| Day off | A day on which one habit is quiet: a weekday that is off, or a date in that habit's days-off list. |

## Habits

1. Each habit is a module. A module owns its prefs, rules, copy, settings tab, and reminder view.
2. Shared code (Engine, Scheduler loop, stores, Reports) never names a specific habit. It uses `switch` on `HabitID` or calls `HabitRules`.
3. Every `switch` on `HabitID` is exhaustive. Never use `default:` and never use `id == .water ? a : b`. A new habit must fail to compile until every place handles it.
4. A habit that is off has no due time and shows no reminder. Its history stays.
5. Habits are independent. Each habit has its own reminder, snooze, ignore timer, and session. A reminder of one habit never waits for, closes, or changes a reminder or session of another habit. There is no queue.
6. Reminders that show at the same time stack down from the top-right corner, in the order they open. A reminder that does not fit above the bottom of the screen starts a new column to the left, from the top. The first one opens on the display that has the mouse pointer. The others join that stack until it is empty. A new reminder never removes the snoozed note of another habit.
7. A lock (any habit at Strict) covers the screen. Only one lock shows at a time: a second habit that reaches its lock shows a Nudgy bubble instead, and locks on a later snooze if no lock shows then. Other reminders keep their own timers behind the lock.
8. "Show a reminder now" in Settings always shows that habit's reminder now, unless that habit already shows one or is in a session.
9. Pause stops new reminders until the pause ends. A reminder that already shows stays.
10. "Rest of day" pauses until the next midnight. It moves each enabled habit to its next slot after that midnight and clears every snooze and closes every open reminder without a snooze, so a slot missed during the pause never shows. A running session continues. The 30 min and 1 hour pauses keep missed reminders: they show when the pause ends.
11. A change to a habit's own schedule settings that moves its due time into the future clears its snooze (for example, today's weekday turned off, a later meditation start time, or a new gym session count). A change to another habit's settings never clears it.
12. A habit that is on but has no next reminder (its rules give no due time, for example Gym work hours that end at or before they start) shows "No reminder" on its card, is left out of the menu bar countdown, and shows no snoozed note.

## Schedules

| Habit | Schedule | Done when |
|---|---|---|
| Water | Every `intervalMinutes`, only between start and end time, until today's glasses meet `dailyGoalGlasses` (rule 3) | The user logs an amount (minimum `Limits.minimumLog`) |
| Reading | Once a day at a set time, on the selected weekdays | A session of `sessionMinutes` ends |
| Meditation | Every `intervalMinutes`, only between start and end time, until today's minutes meet `dailyGoalMinutes`. Then the next reminder is at tomorrow's start time. | A breathing session of `sessionMinutes` ends |
| Gym | On the selected days (all 7 by default). Sessions left = ⌈(goal − today's minutes) ÷ `sessionMinutes`⌉. With no gym done today at or after work start: due = start + (end − start) ÷ (2 × sessions left), so 4 sessions in 9:00–17:00 start at 10:00. After the last gym done today (time d, at or after work start): due = d + the larger of (end − d) ÷ (sessions left + 0.5) and `sessionMinutes`. So sessions done on time give 10:00, 12:00, 14:00, 16:00, and a late session re-spreads the rest. The due time never depends on "now": a missed reminder stays due, and snooze handles the delay. Now or a due time at or after the end, a met goal, a skip, or a day off gives the first reminder of the next day that is on: start + (end − start) ÷ (2 × `sessionsPerDay`). | A gym session ends, or the user taps Done during it. Done early logs the real minutes (rounded, at least 1). |

1. After "done", the next due time starts from the done time, not from the old due time.
2. A due time outside active hours moves to the next start of active hours.
3. Core rule, for every habit: when today's total meets the goal (rule 7), or the user skipped today, the habit has no more reminders today. Its next reminder is the first reminder of the next day that is on (rule 11). `HabitRules.nextDue` owns this check in one place; a habit's rules give only `scheduledDue` and `firstDue(onDayAfter:)`. Raising the goal above today's total brings today's reminders back; a due time already past shows at once (rule 5). A rules type never defines its own `nextDue`, because calls through `any HabitRules` would skip it.
4. Clock times are wall-clock times. On a DST day, 8:00 is 8:00 local time. Settings and the Quick add popup pick clock times with the same chip grid (`TimeMenu`) in 5-minute steps (`Limits.scheduleSlotMinutes`).
5. A settings change never fires a past slot. At launch, a missed slot is still due now. Water and Meditation have no slots: when a settings change moves their due time into the past, the reminder shows at once.
6. A session started when nothing is due and stopped early does nothing: no snooze, no event, the next due time stays.
7. A goal of 0 never counts as met.
8. Weekdays, for every habit: a weekday that is off has no reminder of that habit. All 7 days are on by default. An empty set decodes as all 7 days; Settings never saves an empty set (the last selected day cannot be turned off).
9. A stored value that is unknown (a weekday, slot, or style from a newer version) is dropped or replaced by its default. It never resets the other settings.
10. Single days off, for every habit: each habit has its own list of dates off. A date is a day key `YYYY-MM-DD` in the Gregorian calendar of the user's time zone. Settings adds a date from today to `Limits.daysOffMaxAhead` (365) days ahead, never twice, and at most `Limits.daysOffMax` (100) future dates. Dates are kept forever. Settings lists only today and later. A key that cannot be read is dropped; the other keys and settings stay.
11. No due time falls on a day off. A due day that is off moves to the first reminder of the next day that is on: Water and Meditation start time, Reading set time, Gym first even-spread time (Schedules table). The rules look ahead `Limits.daysOffMaxAhead` + 7 days (372). Settings adds dates off only up to 365 days ahead, so a day that is on is always found and a long break never leaves a habit without its next reminder. Only when no day is on in that window (a hand-edited file), the habit has no next reminder (Habits rule 12). A snooze that ends on a day off waits for the first reminder of the next day that is on, never midnight. When today becomes a day off, that habit's open reminder (bubble, corner popup, or lock) closes at once with no event. A running session continues. Other habits do not change. "Show a reminder now" still works on a day off (Habits rule 8).
12. Water and Meditation pick `intervalMinutes` from the same list, `Limits.intervalChips`: 15, 30, 45, 60, 75, 90, 105, 120. A saved value that is not on the list loads as the nearest value on the list (below 15 loads as 15, above 120 loads as 120). Reading has no interval: it keeps its one set time a day. Gym has no interval: it spreads its sessions (Schedules table).
13. Gym goal: `sessionsPerDay` from `Limits.gymSessionCounts` (1 to 8, default 4) and `sessionMinutes` from `Limits.gymSessionLengths` (2, 3, 5, 10, 15, default 5). A saved value that is not on its list loads as the nearest value on it. A Gym section without `sessionsPerDay` (written by an older version) loads as 4 × 5 and keeps its workout names as ideas.
14. Gym ideas: a list of 1 to `Limits.gymIdeasMax` (8) names, each at most `Limits.gymNameMaxLength` characters. A blank name is dropped on load and save. An empty list loads the 4 default ideas. A list longer than 8 keeps the first 8. The popup shows idea number (gym sessions done today + "Next idea" taps) mod the idea count.

## Escalation

| Strictness (raw value) | Label | Behavior |
|---|---|---|
| `friendly` | Gentle | A reminder each time. It never stays on top. |
| `persistent` | Nudgy | After 1 snooze: stays on top, wiggles, no close button. |
| `strict` | Strict | After 1 snooze: Nudgy. After 2 snoozes: full-screen lock. |

1. Every habit may use Gentle, Nudgy, or Strict. Each habit keeps its own level. At Strict, every habit locks the screen after 2 snoozes. The lock's press-and-hold logs 1 glass for Water and starts the session for Reading, Meditation, and Gym. Before this rule, a saved Strict on Reading or Gym acted as Nudgy. So a Reading or Gym section without the `showsCloseButton` key (written by an older version) loads a saved Strict as Nudgy. After the first save the key is there, and a Strict the user picks stays Strict.
2. Reading shows a corner popup in the top-right by default. It never takes focus from the active app. `ReadingPrefs.reminderStyle` picks `corner` (default) or `focus` (the old centered session).
   - With `corner`, the reading session shows as a small timer pill in the same corner, and the thank-you shows there too.
   - The corner popup snoozes for the General snooze length, like every other reminder.
   - After a snooze of the corner popup (by a tap or by no answer), a note "Boi comes back at {time}" shows for `Timing.cornerNoteDuration` (4 s).
   - Stopping the timer pill early follows Schedules rule 6: it does not count.
   - At Nudgy, the corner popup plays one ping when it shows, then wiggles in silence. It never repeats a sound.
3. The lock always has an emergency skip. A skip resets that habit's streak and skips that habit for the rest of the day, also after a relaunch or a settings change.
4. Raw values never change. They are in saved files. Change only the labels.
5. The Meditation invite follows the same calm rules at Gentle and Nudgy (at Strict it locks after 2 snoozes, like water): it never takes focus from the active app, at Nudgy it wiggles in silence, and its snooze button uses the General snooze length. Its session button "Stop" follows Schedules rule 6: an early stop does not count. Stop works the same while paused.
6. The water thank-you button names the next reminder: "See you in {time}" or "See you tomorrow". While Sathi is paused it says "See you after your break". When water reminders are off it says "Nice one".
7. The Gym invite follows Escalation rule 5 (calm, corner, no focus). Its close button, its "In {n} min" button, and no answer for `ignoreMinutes` are normal snoozes. The popup shows "Try {idea}, {name}", "{sessionMinutes} minutes. You can do this.", and a progress bar with 1 part for each session and the text "{minutes} of {goal} min today · session {n} of {sessionsPerDay}". Its buttons are Start, "Next idea" (a shuffle icon), and snooze. "Next idea" shows the next idea in the popup only. At Nudgy the invite plays one ping, then wiggles in silence. At Strict it locks after 2 snoozes, like water.
8. Each habit has a "Show a close button" switch (`showsCloseButton`, default on for every habit). When it is on, the reminder (bubble or corner popup) shows a close button at the first level (`Level.nudge`). At `Level.persist` (Nudgy or Strict after a snooze) there is no close button. When it is off, the reminder never shows a close button. A tap on close is a normal snooze of that habit only: it adds 1 to that habit's snooze count and never changes another habit.

9. Snooze limit, for every habit: `GeneralPrefs.snoozeLimit` is `nil` (no limit, the default) or a number from `Limits.snoozeLimits` (1 to 15). It counts the snoozes of one reminder: the habit's snooze count, which goes back to 0 when the habit is done or skipped. When the count equals the limit, the reminder has no snooze left:
   - It shows no Snooze button and no close button.
   - No answer for `ignoreMinutes` does not count as a snooze. The reminder has no ignore timer and stays until the user acts.
   - It shows "Skip today". A tap asks to confirm first, because a skip resets the streak. A confirmed skip acts as the lock's emergency skip (rule 3).
   - The level does not change. At Strict, the lock still comes after 2 snoozes when the limit is 2 or more. With a limit of 1 at Strict, the reminder stays as a Nudgy bubble with no snooze and never locks.
   - A Strict habit that reaches its lock while another lock shows gets a Nudgy bubble (Habits rule 7). If that bubble has no snooze left, it becomes the lock as soon as the other lock ends.
   - A change of the limit while a bubble shows takes effect at once: a bubble that gets snoozes back gets a fresh ignore timer, and a bubble that loses its last snooze loses its ignore timer.
   - When 1 snooze is left, the bubble's Snooze button says "Last snooze".
10. Reading list: `ReadingPrefs.list` is a queue of links (`ReadingItem`). Full rules are in `docs/specs/phase-10-reading-list.md`.
   - Today's pick is the first unread item. "Start reading" opens it with the `LinkOpener` port and starts the session. The lock's press-and-hold and every other session start never open a link.
   - Only `http`, `https`, and `file` links are accepted. At most `Limits.readingListMax` unread items.
   - Mark done sets `doneOn` to today. The last `Limits.readingReadKeep` read items are kept; unread items are never removed. Undo moves a read item back to the end of the unread items.
   - "Finished it" during a session finishes the session as done (full minutes) and marks the pick done. An unfinished pick stays first and comes back the next day.
   - List changes never change a due time, a snooze, or a streak.

## History and storage

1. All data stays on the Mac in `~/Library/Application Support/Sathi/`. Nothing goes to a network.
2. `prefs.json` holds settings. `state.json` holds live state. `history/YYYY-MM.json` holds events of one month.
3. History is kept forever. The Engine keeps the last `Limits.monthsInMemory` (3) months in RAM. Older months load on demand and are released after use.
4. Every write is atomic. Every file has `schemaVersion`. A file that cannot be read loads defaults and is not deleted.
5. Every stored time has a precision of 1 second (`Date.wholeSecond`), so memory and disk hold the same value.
6. A new field gets a default value. A breaking change bumps `schemaVersion` and adds a migration with a fixture test.
7. The UserDefaults key `sathi.state.v1` is read by `LegacyMigrator` until the `migrated-v1` marker exists. It is kept as a backup for one release.
8. A history event that this version cannot read (for example, a habit or event kind from a newer version) is not shown and does not count. It stays in its month file unchanged, and every later write of that month keeps it. The other events of the month load as usual. A field that this version does not know in a readable event (for example, a note from a newer version) is also kept and written back.

## Stats and reports

1. A day starts at `Calendar.startOfDay` in the user's time zone. Dates for storage, reports, and export use the Gregorian calendar, whatever the system calendar is.
2. Daily total = sum of `done` event amounts of that habit on that day, after the last streak reset.
3. Day report: buckets of `Limits.reportDayBucketHours`. Week: 7 days from the region's first weekday (`Calendar.firstWeekday`) on the Gregorian calendar, for Reports and Activities ranges. Month: each calendar day. Other places that use `Limits.weekStartWeekday` (the days-off month picker, the streak calendar) do not change.
4. Average per day, "% of goal", and "days met" count only days up to today, never future days. They leave out days off, except a day off with the goal met, which counts as met. If no day counts, the average is 0. Days off use today's weekday setting for every past day (Sathi does not store old settings). Single dates off are kept, so they stay correct.
5. "% of goal" is capped at 100.
6. Export formats in Core: CSV (one row per event), JSON (full backup). PDF has no renderer and no export path.
7. Export (spec 35, 39): Reports "Export CSV" and Activities "Export" write the CSV of the shown range to `~/Downloads` with a free file name and show it in Finder. No save panel (the macOS save panel keeps the app awake, see `performance.md`). A failed write shows "Could not save the file." CSV and JSON are built and written off the main thread. Core JSON backup export stays and is tested.
8. Reports page (spec S4): a tab row of its own, under the header: "All buddies" (selected by default), then one tab per buddy, "<Name> · <goal days>/<days in range>". A buddy that is off has a dimmed tab that cannot be selected; a selection of a buddy that is off shows "All buddies". The "All buddies" tab shows a score card, a "Day by day" grid, the category table (with change and Away), and the streak overview calendar. Score: goals met / goals possible. Goals possible counts, for every buddy that is on, the past days that count (rule 4) and the future days that are on. A day off without the goal met is not a goal day. The headline names the best and the weakest buddy (met ÷ counted days). The change line compares goals met with the range before (the same days so far for the current range) and shows the all-buddies streak. Grid cell: the day value, "Off" on a day off, solid when the goal is met, dim with some progress, dashed for a future day. Only buddies that are on have a row.
9. A buddy tab shows that buddy's chart (value labels, goal line), the range total and change, goal days, best day, daily average, and streak, and the buddy month calendar.
10. The Day range has no goal line, because the goal is per day and the bars are 2-hour buckets.
11. Streak calendars (spec S5): a month, Monday first, with leading blanks. ‹ goes to the month before, › to the month after and is off on the current month. They open on the month of the range's last day, never after today. Today has a white ring. Overview: each day has 4 dots, one per buddy, in the buddy color when its goal was met. A streak day (every buddy that is on that day met its goal) has a green tint and frame. All-buddies streak = streak days in a row up to today. A day where no buddy is on is skipped, today counts only when it is a streak day, and each buddy's streak reset applies. Buddy calendar: the goal met is filled in the buddy color, some progress is a dark buddy tint, none or a day off is gray, a future day is an outline.
12. The menu card says "Day off" when today is a day off for that habit and nothing of that habit is active.
13. The menu card says "✓ Goal met" when today's goal is met (Schedules rule 3), nothing of that habit is active or snoozed, the app is not paused, and today is not a day off. Its progress ring shows a check badge. The action button stays, so the user can log more.
14. Range (spec 27, 28): a range is Day, Week, or Month. Each page has a segment control Day / Week / Month and ‹ › arrows with the range title between them. ‹ moves 1 range back with no limit. › moves 1 range forward and is off on the range that holds today. A change of the range kind keeps the day: the new range holds the first day of the old range, or today when the old range holds today.
15. Compare (spec 29): every total shows a change against the range before. For a past range, the whole previous range counts. For the range that holds now, the previous range is cut at the same point (the same number of whole days from its start, plus the same clock time as now), and a cut end never passes the previous range end. Words: "+6 vs last week", "−1 vs last week", "same as last week"; "yesterday" for Day, "last month" for Month. With no data in both ranges, the change line is hidden.

## Main window

Full rules are in `docs/specs/phase-18-app-window.md`.

1. Sathi has 1 main window: a normal titled macOS window (closable, miniaturizable, resizable, full-size content), Night palette, dark appearance.
2. Sidebar: logo and name, then Today, Activities, Reports, Settings, then a status block ("TRACKER ON" with hours and "asks every {n} min", or "TRACKER OFF"). When Settings is selected, its sub-pages show nested below it: General, Fota, Boi, Shanti, Shokti, Quick reminders, Activity tracker, Time blocks, Sound. The first open of Settings selects General.
3. The Settings window and the Reports window do not exist. Every old path opens the main window on a page with `Engine.openMain(_:)`: menu "Settings" and any "open settings" → Settings → General; "Reports" → Reports; end-of-day "Open full report" → Activities, Day range, that day; time block settings links → Settings → Time blocks; tracker settings links → Settings → Activity tracker. An open window comes to the front and changes page. Sathi activates itself, so the window takes the keyboard.
4. Dock icon: activation policy `.regular` only while the main window is open, else `.accessory` (menu bar only). `LSUIElement` stays `true`.
5. Launch: a launch by the user (Finder, Spotlight, `open`, Dock) and a second launch (`applicationShouldHandleReopen`) open the main window on Today. A launch as a login item opens nothing.
6. Close (the red button or ⌘W) closes the main window; Sathi keeps running in the menu bar and frees the window content. ⌘Q quits.
7. Page state is not saved. Each open starts on the asked page with the current range.
8. Quick panel (spec 16–19): the menu bar panel is short: header, the Now row, the 4 buddies as compact rows (Fota has "+1 glass"), "Quick reminder" and "Take a break" buttons (and "Time block"), a big "Open Sathi" button, and links Reports, Settings, Quit. A running time block keeps its card. The big habit cards, `QuickListCard`, and the old footer are gone from it. It closes when the user picks Open Sathi, Reports, or Settings.
9. Today page (spec 10–15), Settings pages (spec 20–26), and performance (spec 55) follow the spec. Today changes at most 1 time per minute plus at once on a real data change, with no timer of its own.
10. Tracker prompts and notes: Activity tracker rules 3, 13, 14.
## Day summary

Full rules are in `docs/specs/phase-11-day-summary.md`.

1. Every day at `GeneralPrefs.daySummaryMinutes` (default 22:00), when `daySummaryOn` (default on), a corner popup shows today's progress. It shows at most 1 time a day (`LiveState.lastDaySummary`).
2. A missed time shows it later the same day. After midnight it never shows for the day before.
3. A pause does not stop it. It has no snooze, no sound, no history event, and no streak effect. It stays until the user closes it.
4. It always shows 4 rows: off, day off (goal not met), or progress. Its header comes from the progress rows only: all met ("Congratulations"), some met, none met, or a rest day.

## Quick reminders

Full rules are in `docs/specs/phase-12-quick-reminder.md`.

1. A quick reminder is a one-off note ("Call mom") at a time the user picks. It has no streak, goal, history event, stats, or day summary row. It is not a `HabitID`.
2. Text is trimmed, and line breaks become spaces. Empty text is refused. The maximum is `Limits.quickTextMax` (80) characters.
3. At most `Limits.quickMax` (20) pending reminders. An add at 20 is refused.
4. When: "In" a chip from `Limits.quickChips` (5, 15, 30, 60 minutes), or "at" a wall-clock minute. A time at or before now means tomorrow at that minute.
5. Due: a reminder shows when `now >= fireDate` (`snoozedUntil ?? due`). Pauses, weekdays, and days off do not stop it. A time that passes while the Mac sleeps shows at the next tick. Due reminders stack in order of `fireDate`, then `createdAt`.
6. The popup is a corner popup that never takes focus. It has the bell, the "QUICK REMINDER · {time}" eyebrow, the text, "You set this at {time}.", "Done", "In {n} min", and a close button. Accent `Night.quick`.
7. Sound: 1 `.ping` each time a popup shows, at every level. A lock plays `.sosumi`. With sound off, nothing plays.
8. Done (and Delete in the menu) removes the reminder and closes its popup or lock. No thank-you and no event.
9. Level: `QuickPrefs.strictness` (default Nudgy) picks the form from the reminder's own `snoozes` via `EscalationPolicy.presentation(for:snoozes:)`. Gentle: popup each time. Nudgy: stays on top and wiggles after 1 snooze, with no close button. Strict: locks after 2 snoozes. The lock has "Hold for Done" and a "Delete this reminder" link.
10. Only 1 lock shows at a time, shared with buddies. A quick reminder that reaches its lock while another lock shows gets a Nudgy popup. It becomes the lock only when it has no snooze left, as soon as the other lock ends. A buddy waits for a quick lock the same way.
11. Snooze (the button, the close button, or no answer for `ignoreMinutes`) adds 1 to `snoozes`, sets `snoozedUntil = now + snoozeMinutes`, and closes the popup. A note "“{text}” comes back at {time}" shows, cut to `Limits.quickNoteTextMax` (24) characters.
12. The close button shows when `QuickPrefs.showsCloseButton` is on, the level is Gentle, and a snooze is left.
13. The snooze limit (`GeneralPrefs.snoozeLimit`) applies to each reminder. At the limit the popup has no snooze and no close button, and no ignore timer. It shows "No snoozes left. It stays until you tap Done."
14. Storage: `LiveState.quickReminders` in `state.json`. A missing key loads `[]`. An unreadable item, or one with empty text, is dropped and the others stay. Text is cut to 80. Above 20 items, the 20 with the earliest `fireDate` stay. Dates are whole seconds. Open popups and locks are not saved. After a restart a due reminder shows again at the level its saved `snoozes` gives.
15. Settings: `Prefs.quick` holds `strictness` (an unknown value loads Nudgy) and `showsCloseButton` (default on). It is on the Settings → Quick reminders page. A change applies at the next show.
16. Lists and buttons: the list of pending quick reminders moves to Settings → Quick reminders (rows in `fireDate` order: a time pill, the text, a second line "Showing now", "in {time left}", or "Tomorrow", and a delete button, with "+ Quick reminder"). The menu bar quick panel has a "Quick reminder" button, and so does the Today page. "Quick reminder" and "+ Quick reminder" open the add popup.
17. Add popup: a top-right corner popup that takes focus, like the time block Start popup. Esc, Cancel, and a successful Add close it, and focus goes back to the app that had it. The form: "Remind me to" field with a "{n} / 80" counter. 4 chips, with 15 min selected on open. An "or at" time menu (the shared `TimeMenu` grid, pink when a time is picked): a time pick clears the chip, a chip tap replaces the time. Preview "Today at {time}" or "Tomorrow at {time}". "Cancel" and "Add reminder". Add is disabled when the text is blank, and Return adds. At 20 it shows "You have 20 quick reminders. Delete one to add more." and no Add button.
18. The menu bar countdown and status icon do not change.
19. Quick reminders still show during a break, and "Quick reminders still show during a break." shows in the "Take a break" footer menu.
20. No new timer. `upcomingDeadlines()` adds each pending `fireDate` and each popup ignore deadline.

## Time blocks

Full rules are in `docs/specs/phase-13-time-blocks.md`.

1. A time block is not a habit: no streak, goal, history event, stats, or day summary row. It is not a `HabitID`. The calendar event is its only record.
2. Only 1 block runs at a time. A Start while a block runs ends and saves the old block now and shows "Saved {n} min on {title} to {calendar}.", then starts the new one.
3. Start popup: it takes focus (only this popup and the Quick add popup do). Title (optional, empty → "Work", trimmed, line breaks → spaces, max `Limits.blockTitleMax` 60), length chips "Open" + `Limits.blockLengths` (15, 30, 40, 45, 60, 120; the last used is selected, default 30), a calendar menu (this block only), and "Start". Esc and close start nothing.
4. Undo: a Start shows no started note in either mode. In `.widget` mode the pill shows "Undo" in place of the ✕ for `Timing.blockUndoWindow` (4 s) after `startedAt`, then the ✕ comes back. Undo removes the block and writes nothing. "Menu bar only" mode has no Undo.
5. Menu bar: "Paused" and "Locked" win; otherwise, while a block runs, the status text is the block minutes: minutes left for a planned block ("12m"), minutes since Start for an open block ("42m", "2h", "2h 5m"). It changes 1 time per minute.
6. Menu card while a block runs: ring, editable title, progress text, calendar menu, "End now". With no block and access not denied, the menu shows only a "Time block" button in the tool row (Phase 14), which opens the Start popup.
7. Display: `TimeBlockPrefs.display` `.menuBar` (default) or `.widget`. `.widget` shows a 320 × 34 pt pill while the block runs. It opens in the top-right corner. The user can drag it; a dragged pill leaves the corner stack, and each time the pill opens again (a new block, "+15 min", a display change, or a relaunch) it opens in the corner (✕ = End and save; no focus, no animation). `.menuBar` shows no pill. The end popup and the check-in show in both modes.
8. End now (menu or pill ✕): shorter than `Timing.blockMinimum` (60 s) writes nothing and shows "Too short, not saved." Otherwise it saves the event and shows no popup.
9. Planned end: Sathi saves the event at once (`startedAt ..< plannedEnd`) and shows a calm corner popup with "Done" and "+15 min" (no focus; `.ping` when `TimeBlockPrefs.playsSound`). "+15 min" keeps the block running with the end `Timing.blockExtend` after the later of the old end and the tap. The next end updates the saved event (`CalendarWriter.update`: title, calendar, start, end). A missing event (`.calendarMissing`) is saved again for the whole range; a failed update (`.failed`) makes the block wait (rule 12), never a second event. The popup stays until an answer or a new block.
10. Open block: a check-in "Still on {title}?" at `Timing.blockCheckIn` (2 h) after Start, then 2 h after each "Keep going". No answer keeps the block running. At `Timing.blockCap` (12 h) after Start the block ends at `startedAt + 12 h` and is saved.
11. Save: 1 event in the target calendar. Title, start `startedAt`, end; no notes, no alerts; whole seconds. Wall-clock range: sleep and quit time count.
12. Calendar gone or save failed: the block waits (`waitingForCalendar`, `endedAt`) and a corner popup lists the writable calendars with "Save here". Sathi never writes to a calendar the user did not pick. A waiting block has no check-in, no cap, and no status text. Start while a block waits, or when the old block's save fails, returns `.blockWaiting`, closes the Start popup, and shows the calendar-gone popup. "Save here" updates the saved event when one exists. At launch a waiting block shows the calendar-gone popup again. Without calendar access the popup says "Sathi can’t reach your calendars" and shows "Allow calendar access" (asks macOS) when Sathi has not asked yet, or "Open System Settings" after a denial, in place of the list. The menu card shows the same choice. With access but no writable calendar it says so, with no list and no "Save here". It says "is gone" only when Sathi can read calendars and the block's calendar is not among them. While a block waits, the per-minute access check also reads the calendar list again; a change of access or list shows the popup again, so it gets the right size.
13. Calendars: Settings has its own "Time blocks" page in the sidebar, after the buddies: access status, default calendar (writable only, grouped by account), display mode, sound. No default yet: the Start popup uses the macOS default calendar, else the first writable calendar.
14. Access: the first open of the Start popup or the Settings page asks for full calendar access. Denied or restricted: the menu card explains and links to System Settings; Start is off. The Engine reads the access again at each tick and when the Start popup opens.
15. Restart: the block is saved in `state.json` and continues. Deadlines that passed while Sathi was closed run at the next tick (an auto-end saves with the planned end).
16. Pauses, weekdays, and days off do not affect a time block. No new timer: `upcomingDeadlines()` adds the planned end, the check-in, the cap, and the next minute change of the status text.

## Activity tracker

Full rules are in `docs/specs/phase-17-activity-tracker.md`.

1. Not a habit: no streak, goal, `HabitID`, history event, or day summary row. Off by default. Only 1 activity runs; a new one ends the old one now. Shorter than 60 s is not saved.
2. It asks only inside tracker hours, on tracker days, with no break, no time block, and no full-screen lock showing.
3. One activity prompt (spec 41–45) shows at the center of the display that has the mouse pointer. It has 5 reasons: ask (What now?), shortcut, ends (Still on it?), back (after Away), and event (calendar event). Each reason sets its color, tag, title, message, and buttons. Only 1 prompt panel shows; a new reason replaces the content in place. None goes away by itself: it stays until Start, Keep going, or Skip. It never takes the keyboard when it shows. It takes the keyboard at once only when the user opened it (the shortcut, "Switch" or "Log activity", or "Stop"), and a click in it gives it the keyboard. When it closes after it took the keyboard, the keyboard goes back to the app that had it.
3a. C shows every "Ask every" minutes for a work activity: first at the earlier of `start + askEvery` and `start + expected length + ask offset`. A change of "Ask every" applies at once to the pending ask time.
4. Done (and the Started link, spec 50) opens the prompt with a "Started" row (switch time): 5-minute chips from the last answer time to now, default Now. The picked time ends the old activity and starts the new one. Unconfirmed time is never added to an activity.
5. Away (lock, sleep, lid, idle limit) ends the activity. The back reason asks "Where were you?" first (optional; built-in places and up to 8 user-made places), then what to do next. An activity from a calendar event runs on through Away to the earlier of the event end and the return. A buddy session activity runs on through Away while its session exists (no D during the session). Not logged is never stored.
6. Activities never cross midnight. The end-of-day popup shows 1 time a day.
7. Calendar events (opt-in, ticked calendars only): at an event start Sathi logs it and shows a 1-min note (or asks first, by setting). While away it logs it with no question and shows it in the prompt. It skips all-day, declined, and Sathi-written events; Free events count. Category: the last pick for that event title, else the calendar's category (default: the calendar name).
8. Buddy sessions (reading, breathing, gym) end the running activity and log their own. No prompt asks during a session. When a session ends, the ask reason shows with a "Continue {last activity}" button. Water and quick reminders make no activity.
9. Quiet time ("No popups until it ends"): no tracker or buddy popups until the expected end. Buddy reminders wait and show after it. Quick reminders still show.
10. Storage: `activities/YYYY-MM.json`, kept forever. Reports and copy texts are built from it on demand.
11. Report: Away rows have Edit (place, start, end) and Delete. An edit or a past activity that crosses midnight is refused.
11a. Report edit calendar choice (phase 19 S3): the edit section picks "Do not add" or one writable calendar; the activity's current calendar is picked when it opens. Save moves the event and never loses or doubles one: "Do not add" deletes Sathi's event and clears the calendar only when the delete works, else the activity keeps its calendar and event and the edit says the calendar failed; another calendar writes the new event first and deletes the old one only after the write works (a failed write keeps the old calendar and event; a failed delete of the old event removes the new event and keeps the old one; when that removal also fails the activity tracks the new event in the picked calendar, the old event is left behind, and the edit says the calendar failed, so a retry only updates; an activity with no event keeps the new pick so Save retries); other edits are always saved; the same calendar updates the event (and writes one when the activity has none yet). A calendar that is not writable shows as the picked "current" chip and keeps the event. Delete keeps the activity when its event cannot be deleted; an event that is already gone counts as deleted. A row with a calendar and no event shows "Not in calendar"; saving its edit retries. A new past activity with a calendar writes 1 event. Only work activities that Sathi wrote can carry a Sathi event: an activity from a calendar event (`sourceEventID`), Away, a buddy session, or a time block ignores the choice and never deletes the source event. The user sees an error line whenever the calendar did not end up as chosen: "the calendar did not change" when the write or the "Do not add" delete fails, and "the old calendar event could not be removed" only when the old event is left behind. No change to the saved data shape (`Activity.calendarID`, `eventID`).
12. The "Calendar" row in the activity prompt (spec 49), by calendar access. The picked calendar box says what will happen: "One event goes to {calendar} when the activity ends." or "Sathi adds no event for this activity." The event reason shows a read-only row ("Already in your {calendar} calendar, so Sathi adds no copy."). Not asked: the row is active and a tick asks macOS for access; after "Allow" the row ticks the default calendar. Denied: the row shows "Open System Settings" in place of the calendar menu and has no tick. Allowed with no writable calendar: the row is dim, takes no click, and shows "No calendars found on this Mac." Allowed with calendars: the boxes pick the calendar, and a box tap picks it.

13. Prompt actions (spec 52): every old action keeps its Engine call; only the button changes. The table in spec 52 maps each reason to its Start, Keep going, and Skip. A recent card tap or ⌘1–⌘6 fills the text and category and does not start (spec 48). Every choice is a square box, never a dropdown or a pill (spec 49). The event reason has no Ask me row and no Quiet row, and its text field is fixed to the event title (spec 49). The Started link (spec 50) offers 5-minute boxes from a reason-specific time up to now, Now by default.
14. Notes and end of day (spec 53, 54): note F and the end-of-day popup show at the center of the mouse display, never take the keyboard, and keep their content. A note sits above an open prompt with a gap of `UIMetrics.centerStackGap`. The end-of-day popup waits for an open prompt and shows right after it closes, still 1 time a day.

## Breathing session

1. A breathing session runs the selected pattern (`MeditationPrefs.style`). The card shows the time left (m:ss), never a round count.
2. Pause (in a meditation session only; other buddies' sessions never pause) freezes the time left and the phase. Resume continues from the same point. The session end moves later by the paused length. There is no time limit. "Take a break" (Habits rule 9) is a different thing and does not pause a session.
3. A pause survives a restart (`LiveState.meditationSession`). At launch, only when meditation is on and today is not its day off:
   - A session paused today comes back paused.
   - A running session whose end is still ahead and that started today comes back running.
   - Anything else is dropped with no event and no snooze.
4. At midnight a paused session ends. It does not count: no event, no snooze, and the next due time stays.
5. An early Stop (running or paused) follows Schedules rule 6.
6. During a pause, the voice is silent and the music fades out. Both come back on Resume. Other buddies keep reminding (Habits rule 5).
7. Voice guide (`voiceOn`, `voiceVolume`): it speaks once at the start of each phase ("Breathe in", "Hold", "Breathe out", "Rest"), "Let's begin" at the start, and "Well done" at the natural end. It never counts aloud. A cue more than `Timing.cueLateLimit` late is skipped.
8. Background music (`musicOn`, `musicVolume`): one loop that fades in at the start and fades out at the end, at Stop, and at Pause. A missing music file means no music.
9. Bell (`chime`): at the start and at the natural end. Minute tick (`minuteTick`, default off): a very soft tick at each full minute of the session, not at the end.
10. General Sound off silences all session audio, stops a running Preview, and Preview is off. Preview does nothing when both voice and music are off.
11. Default pattern for new installs: Calm 4·6. A saved pattern is kept.
12. No new timer. `upcomingDeadlines()` adds the next phase boundary, the next minute tick, and, while paused, the next midnight.

## Time

1. Core reads time only from `clock.now`. Never `Date()`.
2. Tests use `FakeClock` and fixed dates. A test never waits.