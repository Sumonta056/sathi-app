# Phase 17 test notes

Manual checks for each wave. Run them after the automated tests pass. Write the result (pass, fail, and a note) in `PROGRESS.md`.

Before you start: turn the tracker on, set tracker hours to include now, and set the Away limit to 10 min to test faster.

## After wave 1: core (T1, T2)

1. Run `./scripts/test.sh TrackerTests` and `./scripts/test.sh EngineTrackerFlowTests`. Every Flow-tab step has 1 test. All pass.
2. Load an old `prefs.json` and `state.json` (fixtures): the app starts, the tracker is off, nothing is lost.
3. Write an `activities/2026-11.json` with 1 broken item: the other items load, and the next save keeps unknown fields.

Goals checked by hand here: 

## After wave 2: Mac and prompts (T3, T4, I)

1. Turn the tracker on. At the start of hours, A shows in the corner. Keep typing in your editor: the keys stay in the editor.
2. Open the Recent dropdown and click a row. Wait for C. Try Yes, 5 min, 30 min, Skip, Done. After Done, pick an earlier Started chip and check the log times.
3. Leave C open for 6 min, then answer: the late form shows.
4. Lock the Mac for 2 min, unlock: D shows. Leave the Mac idle past the Away limit (set 10 min to test): D shows "I was here".
5. Press ⌃⌥⌘Space in another app: B opens with the keyboard.
6. Tick No popups for 15 min. Make Water due inside it: no popup, then it shows at the end. Add a quick reminder inside it: it shows.
7. Get a Slack or Mail banner while C shows: C is still there after the banner.
8. Run `./scripts/perf.sh`: idle CPU under 1%, under 10 wakeups a minute.

Goals checked by hand here: P1, G14, G22, G25, G64

## After wave 2: calendar (C)

1. Tick Add to calendar on an activity, end it: 1 event with the real start and end shows in the Calendar app.
2. Edit that activity in the Activities report: the event moves. Delete it: the event goes.
3. Turn on calendar reading and tick 1 calendar. Make a test event 2 min ahead (mark it Free): at its start, note F shows and the activity switches.
4. Set "Ask me first": the prompt shows and stays. Answer late: the activity starts at the event start.
5. Lock the Mac across an event: on unlock, D lists it.
6. Make 2 overlapping events: the first stays, "Also now" shows.
7. Check that all-day and declined events are skipped, and that Sathi does not log its own events.

Goals checked by hand here: P5, G27

## After wave 2: reports and end of day (T5, I)

1. Open Reports → Activities. Step back with ‹ and open a day from the date picker. Days with data show a dot.
2. Check that Real work + Away + Not logged = the tracked span.
3. Edit a start time so it overlaps the item before: refused. Fill a Not logged gap. Add a past activity.
4. Copy for standup and Copy monthly report: paste in a note and compare with rules 35 and 36.
5. Export month: the JSON and CSV files are in Downloads, and Finder shows them. No save panel.
6. End the day after hours: the end-of-day popup shows 1 time and the animation ends in 1.5 s. Turn on Reduce motion: no animation.
7. Run `./scripts/perf.sh --windows` in Terminal (user).

Goals checked by hand here: P2, P3, P4, G44, G45, G53

## Wave 3: settings, menu, and release (T6, I, finish)

1. Open Settings → My day → Activity tracker. Change every row and check that the next ask uses it.
2. Add, rename, and delete a category. Old activities keep the deleted name.
3. The menu shows the running activity with Done. Log activity opens B.
4. `./scripts/test.sh`, `./scripts/lint.sh`, `swift build -c release`: all pass, no new warnings.
5. `./build.sh --install`, `./scripts/perf.sh`, and `./scripts/perf.sh --windows` (user) pass.
6. The README, CLAUDE.md, and website describe the tracker. The website no longer says "It never reads your events".

Goals checked by hand here: G56
