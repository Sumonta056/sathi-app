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
| Buddy | The character of a habit. Water = Fota, Reading = Boi, Meditation = Shanti. |
| Module | All the code of one habit: `SathiCore/Habits/<Name>/` and `SathiUI/Features/<Name>/`. |
| Due | The time a reminder must show. Comes from the habit's `HabitRules.nextDue`. |
| Reminder | What the user sees when a habit is due: bubble, corner popup, or lock. |
| Snooze | The user delays a reminder. Not answering for `ignoreMinutes` also counts as a snooze. |
| Session | A timed activity: reading or meditation. `Phase.session(HabitID)`. |
| Event | One record in history: done, snooze, or skip. `HistoryEvent`. |
| Goal | The daily target of a habit. Water: glasses. Reading and meditation: minutes. |
| Streak | Count of days in a row, up to today, on which the goal was met. |

## Habits

1. Each habit is a module. A module owns its prefs, rules, copy, settings tab, and reminder view.
2. Shared code (Engine, Scheduler loop, stores, Reports) never names a specific habit. It uses `switch` on `HabitID` or calls `HabitRules`.
3. Every `switch` on `HabitID` is exhaustive. Never use `default:` and never use `id == .water ? a : b`. A new habit must fail to compile until every place handles it.
4. A habit that is off has no due time, shows no reminder, and is not in the queue. Its history stays.
5. Only one reminder shows at a time. Other due habits wait in the queue in due-time order.
6. Pause stops all reminders until the pause ends. Due habits wait in the queue.
7. "Rest of day" pauses until the next midnight. It moves each enabled habit to its next slot after that midnight and clears the queue and every snooze, so a slot missed during the pause never shows. The 30 min and 1 hour pauses keep missed reminders in the queue.
8. A settings change that moves a habit's due time into the future removes that habit from the queue and clears its snooze (for example, today's weekday or a meditation slot turned off).

## Schedules

| Habit | Schedule | Done when |
|---|---|---|
| Water | Every `intervalMinutes`, only between start and end time | The user logs an amount (minimum `Limits.minimumLog`) |
| Reading | Once a day at a set time, on the selected weekdays | A session of `sessionMinutes` ends |
| Meditation | At each selected slot (morning, afternoon, evening) | A breathing session ends |

1. After "done", the next due time starts from the done time, not from the old due time.
2. A due time outside active hours moves to the next start of active hours.
3. Reading is skipped for the day when today's minutes already meet the goal.
4. Clock times are wall-clock times. On a DST day, 8:00 is 8:00 local time.
5. A settings change never fires a past slot. At launch, a missed slot is still due now.
6. A session started when nothing is due and stopped early does nothing: no snooze, no event, the next due time stays.
7. A goal of 0 never counts as met.
8. Reading weekdays: a weekday that is off has no reading reminder. The next due time is the set time on the next selected weekday. All 7 days are on by default. An empty set decodes as all 7 days; the Settings window never saves an empty set (the last selected day cannot be turned off).
9. A stored value that is unknown (a weekday, slot, or style from a newer version) is dropped or replaced by its default. It never resets the other settings.

## Escalation

| Strictness (raw value) | Label | Behavior |
|---|---|---|
| `friendly` | Gentle | A reminder each time. It never stays on top. |
| `persistent` | Nudgy | After 1 snooze: stays on top, wiggles, no close button. |
| `strict` | Strict | After 1 snooze: Nudgy. After 2 snoozes: full-screen lock. |

1. Only Water may use Strict. Reading and Meditation never lock the screen.
2. Reading shows a corner popup in the top-right by default. It never takes focus from the active app. `ReadingPrefs.reminderStyle` picks `corner` (default) or `focus` (the old centered session).
3. The lock always has an emergency skip. A skip resets that habit's streak.
4. Raw values never change. They are in saved files. Change only the labels.

## History and storage

1. All data stays on the Mac in `~/Library/Application Support/Sathi/`. Nothing goes to a network.
2. `prefs.json` holds settings. `state.json` holds live state. `history/YYYY-MM.json` holds events of one month.
3. History is kept forever. The Engine keeps the last `Limits.monthsInMemory` (3) months in RAM. Older months load on demand and are released after use.
4. Every write is atomic. Every file has `schemaVersion`. A file that cannot be read loads defaults and is not deleted.
5. Every stored time has a precision of 1 second (`Date.wholeSecond`), so memory and disk hold the same value.
6. A new field gets a default value. A breaking change bumps `schemaVersion` and adds a migration with a fixture test.
7. The UserDefaults key `sathi.state.v1` is read by `LegacyMigrator` until the `migrated-v1` marker exists. It is kept as a backup for one release.

## Stats and reports

1. A day starts at `Calendar.startOfDay` in the user's time zone. Dates for storage, reports, and export use the Gregorian calendar, whatever the system calendar is.
2. Daily total = sum of `done` event amounts of that habit on that day, after the last streak reset.
3. Day report: buckets of `Limits.reportDayBucketHours`. Week: Monday to Sunday. Month: each calendar day.
4. Average per day counts only days up to today, never future days.
5. "% of goal" is capped at 100.
6. Export formats: CSV (one row per event), JSON (full backup), PDF (one-page summary). CSV and JSON are built in Core. PDF is rendered in UI.

## Time

1. Core reads time only from `clock.now`. Never `Date()`.
2. Tests use `FakeClock` and fixed dates. A test never waits.
