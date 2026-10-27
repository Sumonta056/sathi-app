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
| Session | A timed activity: reading, meditation, or gym. `Activity.session(Session)` in `Engine.activities[id]`. |
| Event | One record in history: done, snooze, or skip. `HistoryEvent`. |
| Goal | The daily target of a habit. Water: glasses. Reading and meditation: minutes. Gym: workouts (fixed at 4; each done workout counts 1). |
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
11. A settings change that moves a habit's due time into the future clears its snooze (for example, today's weekday turned off, or a later meditation start time).
12. A habit that is on but has no next reminder (its rules give no due time, for example Gym work hours shorter than one interval) shows "No reminder" on its card, is left out of the menu bar countdown, and shows no snoozed note.

## Schedules

| Habit | Schedule | Done when |
|---|---|---|
| Water | Every `intervalMinutes`, only between start and end time | The user logs an amount (minimum `Limits.minimumLog`) |
| Reading | Once a day at a set time, on the selected weekdays | A session of `sessionMinutes` ends |
| Meditation | Every `intervalMinutes`, only between start and end time, until today's minutes meet `dailyGoalMinutes`. Then the next reminder is at tomorrow's start time. | A breathing session of `sessionMinutes` ends |
| Gym | Every `intervalMinutes` on the selected days (all 7 by default). The first reminder of a day is at the start of work hours plus 1 interval. No reminder at or after the end. Reminders continue after the goal. A last done from an earlier day does not count: the next reminder is 1 interval from now, inside work hours. | A workout session ends, or the user taps Done during it. |

1. After "done", the next due time starts from the done time, not from the old due time.
2. A due time outside active hours moves to the next start of active hours.
3. Reading and Meditation are skipped for the rest of the day when today's minutes already meet the goal.
4. Clock times are wall-clock times. On a DST day, 8:00 is 8:00 local time. Settings picks clock times in 15-minute steps (`Limits.scheduleSlotMinutes`).
5. A settings change never fires a past slot. At launch, a missed slot is still due now. Water and Meditation have no slots: when a settings change moves their due time into the past, the reminder shows at once.
6. A session started when nothing is due and stopped early does nothing: no snooze, no event, the next due time stays.
7. A goal of 0 never counts as met.
8. Weekdays, for every habit: a weekday that is off has no reminder of that habit. All 7 days are on by default. An empty set decodes as all 7 days; the Settings window never saves an empty set (the last selected day cannot be turned off).
9. A stored value that is unknown (a weekday, slot, or style from a newer version) is dropped or replaced by its default. It never resets the other settings.
10. Single days off, for every habit: each habit has its own list of dates off. A date is a day key `YYYY-MM-DD` in the Gregorian calendar of the user's time zone. Settings adds a date from today to `Limits.daysOffMaxAhead` (365) days ahead, never twice, and at most `Limits.daysOffMax` (100) future dates. Dates are kept forever. Settings lists only today and later. A key that cannot be read is dropped; the other keys and settings stay.
11. No due time falls on a day off. A due day that is off moves to the first reminder of the next day that is on: Water and Meditation start time, Reading set time, Gym start plus 1 interval. The rules look ahead `Limits.daysOffMaxAhead` + 7 days (372). Settings adds dates off only up to 365 days ahead, so a day that is on is always found and a long break never leaves a habit without its next reminder. Only when no day is on in that window (a hand-edited file), the habit has no next reminder (Habits rule 12). A snooze that ends on a day off waits for the first reminder of the next day that is on, never midnight. When today becomes a day off, that habit's open reminder (bubble, corner popup, or lock) closes at once with no event. A running session continues. Other habits do not change. "Show a reminder now" still works on a day off (Habits rule 8).
12. Water, Meditation, and Gym pick `intervalMinutes` from the same list, `Limits.intervalChips`: 15, 30, 45, 60, 75, 90, 105, 120. A saved value that is not on the list loads as the nearest value on the list (below 15 loads as 15, above 120 loads as 120). Reading has no interval: it keeps its one set time a day.

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
5. The Meditation invite follows the same calm rules at Gentle and Nudgy (at Strict it locks after 2 snoozes, like water): it never takes focus from the active app, at Nudgy it wiggles in silence, and its snooze button uses the General snooze length. Its session button "Stop" follows Schedules rule 6: an early stop does not count.
6. The water thank-you button names the next reminder: "See you in {time}" or "See you tomorrow". While Sathi is paused it says "See you after your break". When water reminders are off it says "Nice one".
7. The Gym invite follows Escalation rule 5 (calm, corner, no focus). Its close button, its "In {n} min" button, and no answer for `ignoreMinutes` are normal snoozes. "Next idea" shows the next workout in the popup only. At Nudgy the invite plays one ping, then wiggles in silence. At Strict it locks after 2 snoozes, like water.
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
3. Day report: buckets of `Limits.reportDayBucketHours`. Week: Monday to Sunday. Month: each calendar day.
4. Average per day, "% of goal", and "days met" count only days up to today, never future days. They leave out days off, except a day off with the goal met, which counts as met. If no day counts, the average is 0. Days off use today's weekday setting for every past day (Sathi does not store old settings). Single dates off are kept, so they stay correct.
5. "% of goal" is capped at 100.
6. Export formats in Core: CSV (one row per event), JSON (full backup). PDF (one-page summary) needs a UI renderer and has none now.
7. The Reports window has no Export menu for now (2026-10-25: the macOS save panel keeps the app awake, see `performance.md`). Core export stays and is tested. When export comes back: it asks for the file location first. A cancel does nothing and shows nothing. A failed render or write shows an error. CSV and JSON are built and written off the main thread.
8. The Reports window shows one tile per habit. A habit that is off shows a dimmed tile with "Off" and cannot be selected. Its history stays in the totals.
9. The chart, the streak calendar, and the facts (best day, snoozes, longest streak) follow the selected tile. If the selected habit is off, the first enabled habit is used. If no habit is enabled, Water is used.
10. The Day range has no goal line, because the goal is per day and the bars are 2-hour buckets.
11. The streak calendar shows the current month. A day's shade comes from its total divided by the goal: none, under half, under the goal, goal met. A day off without the goal met has its own "off" style and no shade.
12. The menu card says "Day off" when today is a day off for that habit and nothing of that habit is active.

## Time

1. Core reads time only from `clock.now`. Never `Date()`.
2. Tests use `FakeClock` and fixed dates. A test never waits.
