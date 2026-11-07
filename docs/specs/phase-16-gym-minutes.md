# Phase 16: Gym minutes goal, even spread, workout ideas

Terms: `GLOSSARY.md` (Gym goal, Session length, Session count, Workout idea).
Rules: `.claude/rules/business-logic.md` (Words: Goal; Schedules: Gym row, rule 3; Habits rules 12–14; Escalation rule 7).
Design reference: the "FINAL ·" boards on the design canvas https://claude.ai/artifact/CX9q1RKq48qzNFpxjPQi4J.

## Global Constraints

- Every task follows `/feature`: failing tests first (red for the right reason, not a compile error), then code, then `./scripts/test.sh` and `./scripts/lint.sh`.
- No `Date()` in Core. No comments. Max 200 lines per file. No magic numbers.
- Every `switch` on `HabitID` is exhaustive. No `default:`.
- Storage: recipe A of `/data-migration` (add fields, tolerant decoding, no schema bump). History files are never rewritten.
- No new timer, animation, or published state.
- Never weaken a test. When a requirement changes an old test, change it and name the reason.

## Decisions

1. **Goal.** `GymPrefs.sessionsPerDay` (`Limits.gymSessionCounts` 1…8, default 4) × `GymPrefs.sessionMinutes` (`Limits.gymSessionLengths` [2, 3, 5, 10, 15], default 5). `GymRules.dailyGoal` = the product. A value not on its list loads as the nearest value on it.
2. **Even spread.** In `GymRules.nextDue`:
   - left = ⌈max(0, goal − doneToday) ÷ sessionMinutes⌉.
   - left = 0 or `skipToday`: the first reminder of the next day that is on.
   - from = max(now, today's work start). Due = from + (end − from) ÷ (2 × left).
   - now at or after today's end, or today is off: the first reminder of the next day that is on.
   - First reminder of a day = start + (end − start) ÷ (2 × sessionsPerDay).
   - `lastDone` is not used.
   - End at or before start: no reminder (`.distantFuture`).
3. **Interval removed.** `GymPrefs.intervalMinutes` is removed. The decoder ignores the old key. `Prefs.scheduleKey` uses `sessionsPerDay` and `sessionMinutes`.
4. **Ideas.** `GymPrefs.ideas: [String]`, 1…`Limits.gymIdeasMax` (8). Names are trimmed and cut to `Limits.gymNameMaxLength`. Blank names are dropped. An empty list gives `GymIdeas.defaults` (the 4 old default names). The `GymWorkout` type goes away; a private legacy shape decodes the old `workouts` array (names only).
5. **Old prefs.** A gym section without `sessionsPerDay` loads 4 × 5 and takes its names from `workouts`. With `ideas` present, `ideas` wins.
6. **Real minutes.** `finishSession(.gym)` logs max(1, round((min(now, end) − start) ÷ 60)). The other habits do not change.
7. **Old history.** `LiveState.gymMinutesSince: Date?` (whole seconds). On Engine init it is set to `clock.now` when nil, and saved. Every event list that the Engine reads from `HistoryStore` goes through the pure `GymLegacyMinutes.apply(_:since:)`: a gym done event before `since` gets amount `Limits.gymLegacyDoneMinutes` (5). Files stay as they are. Exports stay raw.
8. **Idea rotation.** Index = (gym done events today + `gymIdea`) mod `ideas.count`. A running session keeps its own index.
9. **Text.** Menu card, day summary: "{done} of {goal} min". Report tile unit: "min".
10. **Popup** (`GymInvite`):
    - Title "Try {idea}, {name}". Line "{sessionMinutes} minutes. You can do this."
    - `GymProgressBar`: `sessionsPerDay` parts, filled = min(sessionsPerDay, ⌊doneToday ÷ sessionMinutes⌋).
    - Label "{done} of {goal} min today · session {n} of {sessionsPerDay}", where n = min(filled + 1, sessionsPerDay).
    - Buttons: Start, "Next idea" as a shuffle icon with that accessibility label, snooze as today.
11. **Settings.**
    - New `GymGoalCard`: "Sessions a day" chips, "Each session" chips, a summary "Daily goal: {g} min · {n} × {m} min", and "Popups at {times}".
    - `GymRhythmCard` loses `IntervalRow`.
    - `GymWorkoutsCard` becomes "My workout ideas": 1 row per idea with a name field and a remove button (disabled at 1 row), and "+ Add idea" (disabled at 8). A new row starts blank; a blank row is dropped on save.
    - `GymTimerCard` uses `sessionMinutes`.

## Tasks

1. Core prefs and constants: `Limits`, `GymPrefs`, `GymIdeas`, `Prefs.scheduleKey`. Tests: `GymPrefsTests`, `GymWorkoutDecodingTests` (now legacy decoding), `LenientPrefsDecodingTests`.
2. Core rules: `GymRules`. Tests: `GymRulesTests`, `GymDaysOffRulesTests`, `NextSlotTests`.
3. Engine: real minutes, cutover, rotation, text. Tests: `EngineGymTests`, `EngineGymSnoozeTests`, `EngineDaySummary*`, `ReportScreenTileTests`, `GymLegacyMinutesTests` (new), `WholeSecondTests`.
4. UI: popup, progress bar, goal card, ideas card, rhythm card, timer card. Tests: `GymInviteTests`, `GymSettingsTabTests`, `GymTimerCardTests`, `HabitCardTests`.
5. Docs: `CLAUDE.md` text about Shokti, README, then `/sathi-website`.
