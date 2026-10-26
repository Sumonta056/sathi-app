# Gym (Shokti) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a fourth habit, Gym, with the buddy Shokti. It suggests 1 of 4 user-edited short workouts every interval during work hours, in a calm corner popup with a timer.

**Architecture:** A new habit module of kind C in `/add-habit` (interval inside active hours, timed session), modeled on Meditation. Core gets `GymPrefs`, `GymRules`, and a small `Engine+Gym.swift` for the 2 new actions ("Next idea", "Not now"). UI gets the corner invite, a corner timer card, a corner thank-you, a buddy drawing, and a Settings tab. No `LiveState` field. No schema bump.

**Tech Stack:** Swift 5.9, SwiftUI + AppKit, Swift Testing, ViewInspector 0.10.

**Spec:** `docs/specs/gym-shokti-design.md`. Also follow `.claude/skills/add-habit/SKILL.md`: it lists every switch and file. This plan gives the decisions that skill leaves open.

## Global Constraints

- `HabitID.gym`, raw value `"gym"`, `name` "Gym", `buddy` "Shokti". Raw values never change.
- Popup and hero label: `SHOKTI · GYM`. Timer label: `SHOKTI · {workout name}`.
- Accent `#CDEF5A`, hero fill `#222A16`, hero border `#46561F`.
- `GymPrefs.enabled` defaults to `false`.
- Defaults: interval 60 min (chips 45, 60, 90); work hours 9:00 to 17:00; work days Mon to Fri; 4 workouts: "Neck and shoulder stretch" 5, "Short walk" 5, "10 squats" 3, "Wall push-ups" 3. Minutes choices 1, 2, 3, 5, 10. Name max 40 characters.
- Daily goal: 4 workouts, fixed. Each done workout writes `amount` 1. Reminders continue after the goal.
- Gym never locks: `Prefs.strictness(.gym)` uses `withoutLock`. Strictness default `.friendly`.
- No code comments. Max 200 lines per file. No magic numbers: values go in `Limits`, `Timing`, or `UIMetrics`. Core reads time only from `clock.now`.
- Every `switch` on `HabitID` is exhaustive. No `default:`.
- Ask the user before each `git commit`. Work on branch `feature/gym-shokti`, never on `main`.

## Review Focus

1. A `prefs.json` with 3 or 5 workouts, an empty or blank name, a 60-character name, or 7 minutes always loads as 4 valid rows (Task 2 test `decodingAlwaysGivesFourValidWorkouts`).
2. Due times on Friday at 16:30, on a weekend, and with a 90-minute interval near the end of work hours never fall outside work hours (Task 3 tests `fridayEveningMovesToMondayFirstReminder`, `lastReminderNeverAtOrAfterEnd`).
3. An ignored Gym popup comes back 1 interval later, not every snooze length, and it never grows to Nudgy from ignores alone (Task 4 test `ignoredPopupComesBackNextIntervalAtGentle`).
4. "Next idea", then Start, runs the workout on screen. "Next idea" does not move the ignore deadline (Task 4 tests `startRunsTheShownWorkout`, `nextIdeaKeepsTheIgnoreDeadline`).
5. A Gym "Not now" never closes or changes a Water or Meditation reminder that shows at the same time (Task 4 test `notNowLeavesOtherHabitsAlone`).

---

### Task 1: Branch, ignore file, and business rules

**Files:**
- Modify: `.gitignore`
- Modify: `.claude/rules/business-logic.md`
- Move: `docs/specs/gym-shokti-design.md` stays; add a line for it in `docs/ROADMAP.md` (new phase "7 Gym (Shokti)")

**Interfaces:**
- Produces: the rules that every later task's tests follow.

- [ ] **Step 1: Create the branch**

Run: `git switch -c feature/gym-shokti`
Expected: `Switched to a new branch 'feature/gym-shokti'`

- [ ] **Step 2: Add `.superpowers/` to `.gitignore`**

- [ ] **Step 3: Edit `.claude/rules/business-logic.md`**

1. Words: Buddy row adds "Gym = Shokti". Goal row adds "Gym: workouts".
2. Schedules table, new row: Gym | Every `intervalMinutes` on the selected work days. The first reminder of a work day is at the start of work hours plus 1 interval. No reminder at or after the end. Reminders continue after the goal. | A workout session ends, or the user taps Done during it.
3. Schedules rule 3 stays as it is (it names only Reading and Meditation).
4. Escalation rule 1: "Water and Meditation may use Strict. Reading and Gym never lock the screen."
5. New Escalation rule 7: the Gym invite follows Escalation rule 5 (calm, corner, no focus). Its close button, and no answer for `ignoreMinutes`, mean "Not now": a `.snooze` event, the next reminder 1 interval later, the snooze count goes back to 0, the streak stays. Its "In {n} min" button is a normal snooze. "Next idea" shows the next workout in the popup only.
6. Words, Snooze row: add "Except Gym: no answer means Not now (Escalation rule 7)."

- [ ] **Step 4: Ask the user, then commit**

```bash
git add .gitignore .claude/rules/business-logic.md docs/ROADMAP.md docs/specs/gym-shokti-design.md docs/superpowers/plans/2026-10-26-gym-shokti.md
git commit -m "docs: add Gym (Shokti) rules, design, and plan"
```

---

### Task 2: Gym prefs

**Files:**
- Create: `Sources/SathiCore/Habits/Gym/GymWorkout.swift`
- Create: `Sources/SathiCore/Habits/Gym/GymPrefs.swift`
- Modify: `Sources/SathiCore/Constants/Limits.swift`
- Modify: `Sources/SathiCore/Models/Prefs.swift` (field `gym`, `init(from:)`, `scheduleKey` only; `isEnabled` and `strictness` change in Task 3)
- Test: `Tests/SathiCoreTests/GymPrefsTests.swift`, `Tests/SathiCoreTests/LenientPrefsDecodingTests.swift`

**Interfaces:**
- Produces:
  - `package struct GymWorkout: Codable, Equatable, Sendable { package var name: String; package var minutes: Int }`
  - `GymWorkout.defaults: [GymWorkout]` (the 4 default rows, in order)
  - `package struct GymPrefs: Codable, Equatable, Sendable` with `enabled = false`, `intervalMinutes = 60`, `startMinutes = Limits.gymStartMinutes`, `endMinutes = Limits.gymEndMinutes`, `weekdays: Set<Weekday> = Limits.gymWorkDays`, `workouts = GymWorkout.defaults`, `strictness: Strictness = .friendly`, `sortedWeekdays: [Weekday]`
  - `GymPrefs.cleaned(_ workouts: [GymWorkout]) -> [GymWorkout]` (static): always 4 rows
  - `GymPrefs.workout(at index: Int) -> GymWorkout`: `workouts[index mod 4]`, safe for any `Int`
  - `Limits.gymWorkoutCount = 4`, `gymDailyGoal = 4`, `gymNameMaxLength = 40`, `gymWorkoutLengths = [1, 2, 3, 5, 10]`, `gymIntervalChips = [45, 60, 90]`, `gymStartMinutes = 9 * 60`, `gymEndMinutes = 17 * 60`, `gymWorkDays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]`
  - `Prefs.gym: GymPrefs`

- [ ] **Step 1: Write the failing tests** (suite "Gym prefs", copy the shape of `MeditationPrefsTests.swift`)

```swift
@Test func defaultsMatchTheDesign() {
    let p = GymPrefs()
    #expect(p.enabled == false)
    #expect(p.intervalMinutes == 60)
    #expect(p.startMinutes == 9 * 60)
    #expect(p.endMinutes == 17 * 60)
    #expect(p.sortedWeekdays == [.monday, .tuesday, .wednesday, .thursday, .friday])
    #expect(p.strictness == .friendly)
    #expect(p.workouts.map(\.name) == ["Neck and shoulder stretch", "Short walk", "10 squats", "Wall push-ups"])
    #expect(p.workouts.map(\.minutes) == [5, 5, 3, 3])
}

@Test func oldPrefsWithoutGymDecodeToDefaults() throws

@Test func roundTripKeepsEveryField() throws

@Test(arguments: [3, 5])
func decodingAlwaysGivesFourValidWorkouts(count: Int) throws

@Test func blankNameFallsBackToTheDefaultOfThatRow() {
    let rows = GymPrefs.cleaned([GymWorkout(name: "  ", minutes: 5)] + Array(GymWorkout.defaults.dropFirst()))
    #expect(rows[0].name == "Neck and shoulder stretch")
}

@Test func longNameIsCutToFortyCharacters() {
    let rows = GymPrefs.cleaned([GymWorkout(name: String(repeating: "a", count: 60), minutes: 5)])
    #expect(rows[0].name.count == 40)
    #expect(rows.count == 4)
}

@Test func unknownMinutesFallBackToTheDefaultOfThatRow() {
    let rows = GymPrefs.cleaned([GymWorkout(name: "Lunges", minutes: 7)])
    #expect(rows[0] == GymWorkout(name: "Lunges", minutes: 5))
}

@Test func workoutIndexWrapsAround() {
    let p = GymPrefs()
    #expect(p.workout(at: 4) == p.workouts[0])
    #expect(p.workout(at: 6) == p.workouts[2])
}

@Test func scheduleKeyChangesWithEveryGymTimingField()
```

`decodingAlwaysGivesFourValidWorkouts`: encode JSON with `count` rows. Expect 4 rows. Missing rows come from `GymWorkout.defaults` at the same position. Extra rows are dropped.

`scheduleKeyChangesWithEveryGymTimingField`: `enabled`, `intervalMinutes`, `startMinutes`, `endMinutes`, `weekdays` each change `Prefs.scheduleKey`. Workout names and minutes do not.

In `LenientPrefsDecodingTests.swift`: an unknown `strictness` string and an unknown weekday number in `gym` decode to the defaults and keep the other gym fields. An empty `weekdays` array decodes to Mon to Fri.

- [ ] **Step 2: Run the tests to see them fail**

Run: `./scripts/test.sh "Gym prefs"`
Expected: FAIL, `cannot find 'GymPrefs' in scope`.

- [ ] **Step 3: Implement**

Copy the decode and encode shape of `ReadingPrefs`. Use `value`, `known`, and `knownSet(.weekdays, or: d.weekdays, keepsEmpty: false)`. Decode `workouts` with `value(.workouts, or: d.workouts)`, then pass it through `cleaned`. Encode weekdays as `sortedWeekdays`. `cleaned` trims white space before the blank check and cuts with `prefix(Limits.gymNameMaxLength)`.

- [ ] **Step 4: Run the tests to see them pass**

Run: `./scripts/test.sh "Gym prefs"` and `./scripts/test.sh SathiCoreTests`
Expected: PASS. No other suite fails.

- [ ] **Step 5: Ask the user, then commit**

```bash
git commit -m "feat(core): add Gym prefs and workouts"
```

---

### Task 3: The Gym habit, its rules, and every switch

This task adds `HabitID.gym`, so the whole package fails to compile until every switch handles it. UI switches get their final simple values here. The UI views in Tasks 5 to 7 replace only the temporary view routes.

**Files:**
- Modify: `Sources/SathiCore/Models/HabitID.swift`, `Models/Prefs.swift` (`isEnabled`, `strictness`), `Models/Persisted.swift`
- Create: `Sources/SathiCore/Habits/Gym/GymRules.swift`
- Modify: `Sources/SathiCore/Habits/HabitRules.swift`
- Create: `Sources/SathiCore/Formatting/Copywriter+Gym.swift`; Modify: `Formatting/Copywriter.swift`
- Modify: every Core and UI file in `/add-habit` step 6
- Test: `Tests/SathiCoreTests/GymRulesTests.swift`, `Tests/SathiCoreTests/GymCopyTests.swift`, and the fixed lists in `/add-habit` step 10

**Interfaces:**
- Consumes: `GymPrefs`, `Limits.gym*` (Task 2).
- Produces:
  - `HabitID.gym`
  - `package struct GymRules: HabitRules`, `init(prefs: Prefs, calendar: Calendar = .current)`, `dailyGoal == Double(Limits.gymDailyGoal)`
  - `Persisted.lastDone(.gym)`: the last `.done` event date of `.gym`
  - `Copywriter.gymInviteHint(_ w: GymWorkout) -> String` returns `"\(w.name) · \(w.minutes) min"`
  - `Copywriter.gymTimerLine() -> String`: 1 kind line, the same for every workout
  - Values for the switches:

| Switch | `.gym` value |
|---|---|
| `Prefs.strictness` | `withoutLock(gym.strictness)` |
| `lockConfirmed` | `startSession(.gym)` |
| `celebrationSound` | `.hero` |
| `startSound` | `nil` |
| `Engine+Loop` `greeting` | `.tink` |
| `usesCorner` | `true` |
| report tile value | `"\(Int(amount.rounded()))"` |
| report tile unit | `"workouts"` |
| `Night.accent` / `heroFill` / `heroBorder` | `#CDEF5A` / `#222A16` / `#46561F` |
| `BuddyKind` | new case `kettlebell`; Task 5 draws it. Here draw it with the `pebble` drawing |
| `UIController.bubblePanel` | `presentCorner(BubbleView(id: id, level: level))`, like `.meditation` (Task 6 swaps the view) |
| `UIController.sessionView` | `SessionView(id: id)` (Task 6 swaps it) |
| `SettingsView` `.habit(.gym)` | `HabitSettingsPage` stub that shows the hero only (Task 7 swaps it) |
| `LockView` lines | real lines, never shown |
| `SessionCopy` | title "Move with Shokti", body `Copywriter.gymTimerLine()`, breath `nil` |

`sessionMinutes(.gym)` is the minutes of the current workout. Task 4 adds that. In this task return `data.prefs.gym.workouts[0].minutes`.

- [ ] **Step 1: Write the failing rules tests** (suite "GymRules", shape of `MeditationRulesTests.swift`; 2026-03-04 is a Wednesday, 2026-03-06 a Friday, 2026-03-09 a Monday)

```swift
@Test func idAndGoal() { #expect(rules.id == .gym); #expect(rules.dailyGoal == 4) }

@Test func beforeWorkStartsFirstReminderIsStartPlusInterval() {
    #expect(rules.nextDue(now: day(2026, 3, 4, 7), lastDone: nil, doneToday: 0, skipToday: false) == day(2026, 3, 4, 10))
}

@Test func doneAtElevenIsDueAtTwelve() {
    #expect(rules.nextDue(now: day(2026, 3, 4, 11), lastDone: day(2026, 3, 4, 11), doneToday: 1, skipToday: false) == day(2026, 3, 4, 12))
}

@Test func goalMetDoesNotStopTheDay() {
    #expect(rules.nextDue(now: day(2026, 3, 4, 14), lastDone: day(2026, 3, 4, 14), doneToday: 4, skipToday: false) == day(2026, 3, 4, 15))
}

@Test func fridayEveningMovesToMondayFirstReminder() {
    #expect(rules.nextDue(now: day(2026, 3, 6, 16, 30), lastDone: day(2026, 3, 6, 16, 30), doneToday: 3, skipToday: false) == day(2026, 3, 9, 10))
}

@Test func lastDoneYesterdayGivesTodaysFirstReminder() {
    #expect(rules.nextDue(now: day(2026, 3, 5, 8), lastDone: day(2026, 3, 4, 16, 30), doneToday: 0, skipToday: false) == day(2026, 3, 5, 10))
}

@Test func lastReminderNeverAtOrAfterEnd()

@Test func skipTodayMovesToNextWorkDay() {
    #expect(rules.nextDue(now: day(2026, 3, 4, 11), lastDone: nil, doneToday: 0, skipToday: true) == day(2026, 3, 5, 10))
}

@Test func activeOnlyInWorkHoursOnWorkDays() {
    #expect(rules.isActiveTime(day(2026, 3, 4, 9)))
    #expect(!rules.isActiveTime(day(2026, 3, 4, 17)))
    #expect(!rules.isActiveTime(day(2026, 3, 7, 11)))
}

@Test func nextActiveStartSkipsTheWeekend() {
    #expect(rules.nextActiveStart(after: day(2026, 3, 6, 18)) == day(2026, 3, 9, 9))
}

@Test func dstMorningKeepsWallClockTime()
```

`lastReminderNeverAtOrAfterEnd`: interval 90, done at 16:00 Wednesday. Expect Thursday 10:30.
`dstMorningKeepsWallClockTime`: copy the DST setup of `DayClockDSTTests.swift`. On the DST day, before work, expect 10:00 local time.

- [ ] **Step 2: Write the failing habit and copy tests**

```swift
@Test func gymNamesTheBuddyShokti() { #expect(HabitID.gym.name == "Gym"); #expect(HabitID.gym.buddy == "Shokti"); #expect(HabitID.gym.rawValue == "gym") }
@Test func storedStrictGymActsAsNudgy() { var p = Prefs(); p.gym.strictness = .strict; #expect(p.strictness(.gym) == .persistent) }
@Test func inviteHintNamesWorkoutAndMinutes() { #expect(Copywriter.gymInviteHint(GymWorkout(name: "Short walk", minutes: 5)) == "Short walk · 5 min") }
@Test func gymCopyHasNudgeAndPersistLines()
@Test func gymComesBackNoteNamesShokti()
```

`gymComesBackNoteNamesShokti`: `Copywriter.comesBack(.gym, …)` starts with "Shokti comes back at".

- [ ] **Step 3: Run to see them fail**

Run: `./scripts/test.sh "GymRules"`
Expected: FAIL, `type 'HabitID' has no member 'gym'`.

- [ ] **Step 4: Implement `GymRules`**

```text
interval = gym.intervalMinutes min
firstOf(day) = start of work hours on day + interval
isWorkDay(day) = weekday of day is in gym.weekdays (empty set counts as Mon to Fri)

nextDue:
  if skipToday: return firstReminder(onOrAfter: next day after now)
  c = (lastDone ?? now) + interval
  if isWorkDay(c) and c < end of work hours on c's day: return max(c, firstOf(c's day))
  return firstReminder(onOrAfter: day after c)

firstReminder(onOrAfter d): for step in 0...7 days, the first work day whose firstOf(day) < end of work hours on that day.
  Fallback after 7 steps: firstOf(d + 7 days).
```

`goalMetDoesNotStopTheDay` must pass: `doneToday` is not read. Use `DayClock` for all wall-clock times.

- [ ] **Step 5: Add `.gym` to every switch**

Run `swift build`. Fix Core errors first, then UI errors, with the table above. Then run the `grep` in `/add-habit` step 6 and handle each `== .water` style check. Fix the fixed habit lists in `/add-habit` step 10, and say in the commit message why each list changed.

- [ ] **Step 6: Run all tests**

Run: `./scripts/test.sh`
Expected: PASS, with the new suites in the count.

- [ ] **Step 7: Ask the user, then commit**

```bash
git commit -m "feat(core): add the Gym habit and its schedule"
```

---

### Task 4: Engine actions for Gym

**Files:**
- Create: `Sources/SathiCore/Engine/Engine+Gym.swift`
- Modify: `Sources/SathiCore/Models/ReminderState.swift` (`Session.workout`)
- Modify: `Sources/SathiCore/Engine/Engine.swift` (published `gymIdea`)
- Modify: `Sources/SathiCore/Engine/Engine+Session.swift` (`startSession`, `finishSession`, `sessionMinutes`)
- Modify: `Sources/SathiCore/Engine/Engine+Loop.swift` (`endIfExpired`, reset `gymIdea` in `present`)
- Test: `Tests/SathiCoreTests/EngineGymTests.swift`

**Interfaces:**
- Consumes: `GymPrefs.workout(at:)`, `GymRules`, `HabitID.gym`.
- Produces:
  - `Session.workout: Int?` (new init parameter `workout: Int? = nil`)
  - `@Published package internal(set) var gymIdea = 0` on `Engine`
  - `package var gymWorkoutIndex: Int` = `Int(today's gym total) + gymIdea`, then mod 4
  - `package var gymWorkout: GymWorkout` = the running session's workout if a Gym session runs, else `data.prefs.gym.workout(at: gymWorkoutIndex)`
  - `package func nextGymIdea()`: only while `.gym` shows a bubble; `gymIdea += 1`; does not touch the activity or its ignore deadline
  - `package func notNow(_ id: HabitID)`: only while `id` shows a bubble; record `.snooze(id, at: n)`; close the bubble; `habits[id] = HabitState(nextDue: freshDue(id, lastDone: n))`; if `usesCorner(id)`, `presenter.showSnoozed(id, until:)` with that due time; `requestTick()`
  - `func ignoreGoesToNextInterval(_ id: HabitID) -> Bool`: exhaustive switch, `true` only for `.gym`. `endIfExpired` calls `notNow` when it is `true`, else `snooze`.
  - `finishSession(.gym)` records amount `1` and celebrates with `1`. Other habits keep their minutes. Use an exhaustive switch `doneAmount(_ id: HabitID, minutes: Double) -> Double`.
  - `startSession(.gym)` stores `workout: gymWorkoutIndex` and uses that workout's minutes.

`Engine+Gym.swift` holds `gymWorkoutIndex`, `gymWorkout`, `nextGymIdea`, `notNow`, `ignoreGoesToNextInterval`. Keep `Engine+Actions.swift` under 200 lines.

- [ ] **Step 1: Write the failing tests** (suite "Engine gym", `EngineHarness` at `day(2026, 3, 4, 10)`, gym enabled, other habits off unless a test needs them)

```swift
@Test func firstReminderShowsAtTenInTheCorner()
@Test func firstWorkoutOfTheDayIsWorkoutOne() { #expect(h.engine.gymWorkout.name == "Neck and shoulder stretch") }
@Test func nextIdeaShowsTheNextWorkoutAndWrapsAfterFour()
@Test func nextIdeaKeepsTheIgnoreDeadline()
@Test func startRunsTheShownWorkout()
@Test func doneEarlyCountsOneWorkout()
@Test func timerEndCountsOneWorkout()
@Test func stopDoesNotCount()
@Test func secondReminderAfterOneDoneShowsWorkoutTwo()
@Test func closeIsNotNowAndComesBackNextInterval()
@Test func ignoredPopupComesBackNextIntervalAtGentle()
@Test func snoozeButtonIsANormalSnooze()
@Test func notNowLeavesOtherHabitsAlone()
@Test func remindersContinueAfterFourWorkouts()
@Test func noReminderOnSaturday()
```

Assertions:
- `firstReminderShowsAtTenInTheCorner`: start at 9:00, advance 60 min. `h.presenter.calls` holds `showBubble(.gym, .nudge)`; `h.engine.usesCorner(.gym)`.
- `nextIdeaShowsTheNextWorkoutAndWrapsAfterFour`: tap `nextGymIdea()` 1 time, name is "Short walk". 4 more times, name is "Short walk" again. No new history event.
- `nextIdeaKeepsTheIgnoreDeadline`: read the `.bubble` deadline, call `nextGymIdea()`, the deadline is the same.
- `startRunsTheShownWorkout`: 2 × `nextGymIdea()`, `startSession(.gym)`. `session(.gym)?.workout == 2`; `end - start == 3 min`; `gymWorkout.name == "10 squats"`.
- `doneEarlyCountsOneWorkout`: start, advance 1 min, `finishSession(.gym)`. Last event is `.done(.gym, 1, …)`; `celebration.amount == 1`; next due = done time + 60 min.
- `timerEndCountsOneWorkout`: start, advance 5 min. Same checks.
- `stopDoesNotCount`: start from the reminder, `stopSession(.gym)`. No `.done` event.
- `secondReminderAfterOneDoneShowsWorkoutTwo`: done 1, advance to the next reminder. `gymWorkout.name == "Short walk"`; `gymIdea == 0`.
- `closeIsNotNowAndComesBackNextInterval`: at 10:00 call `notNow(.gym)`. Event `.snooze`; `state(.gym).nextDue == 11:00`; `snoozes == 0`; `snoozedUntil == nil`; `presenter.calls` holds `showSnoozed(.gym, until: 11:00)`.
- `ignoredPopupComesBackNextIntervalAtGentle`: set General `ignoreMinutes` 5. At 10:00 the popup shows; advance 5 min; it closes. Advance 50 min: no popup. Advance to 11:05: popup shows at `.nudge`, not `.persist`.
- `snoozeButtonIsANormalSnooze`: strictness `.persistent`; `snooze(.gym)`; `snoozedUntil == now + snoozeMinutes`; the next show is `.persist`.
- `notNowLeavesOtherHabitsAlone`: water and gym both due at 10:00. `notNow(.gym)`. `activities[.water]` still a bubble; the water ignore deadline is the same.
- `remindersContinueAfterFourWorkouts`: 4 done workouts by 14:00, advance 60 min, a popup shows.
- `noReminderOnSaturday`: harness at `day(2026, 3, 7, 9)`, advance 8 hours, no `showBubble(.gym, _)`.

- [ ] **Step 2: Run to see them fail**

Run: `./scripts/test.sh "Engine gym"`
Expected: FAIL, `value of type 'Engine' has no member 'gymWorkout'`.

- [ ] **Step 3: Implement** the interfaces above. Add 1 helper with an exhaustive switch, `resetsIdea(_ id: HabitID) -> Bool` (`true` only for `.gym`). Do not use an `id == .gym` check (Habits rule 3). Set `gymIdea = 0` when the helper is `true` at 2 places: in `present(_:)`, and after `finishSession`. Do not reset it in `startSession`, because the running session already stores its workout.

- [ ] **Step 4: Run all Core tests**

Run: `./scripts/test.sh SathiCoreTests`
Expected: PASS. `EngineFlowTests` and `EngineIndependenceTests` still pass.

- [ ] **Step 5: Ask the user, then commit**

```bash
git commit -m "feat(core): Gym next idea, not now, and one-workout done"
```

---

### Task 5: Shokti buddy drawing

**Files:**
- Create: `Sources/SathiUI/Buddy/BuddyCanvas+Kettlebell.swift`
- Modify: `Sources/SathiUI/Buddy/BuddyCanvas.swift`, `Buddy/BuddyCanvas+Pebble.swift` (`faceInk`, `cheekFill`), `Buddy/BuddyKind.swift`
- Test: `Tests/SathiUITests/BuddyKindTests.swift` (or the existing buddy test file)

**Interfaces:**
- Consumes: `BuddyKind.kettlebell` (Task 3).
- Produces: `drawKettlebell(in:)` in the `switch kind`.

- [ ] **Step 1: Write the failing test**: `BuddyKind(habit: .gym) == .kettlebell`, and a `BuddyView(habit: .gym)` renders without a crash in ViewInspector.
- [ ] **Step 2: Run** `./scripts/test.sh SathiUITests`. Expected: these tests pass already, because Task 3 routes `.kettlebell` to the pebble drawing. They guard the route while you change the drawing. The drawing itself is checked by eye in Task 8 (`ui-verifier`).
- [ ] **Step 3: Draw** a round body with a handle on top, the accent fill, open eyes and cheeks like Fota. Animation rules: `TimelineView` at `UIMetrics.animationFrameInterval`, paused when hidden.
- [ ] **Step 4: Run** `./scripts/test.sh SathiUITests`. Expected: PASS.
- [ ] **Step 5: Ask the user, then commit** `feat(ui): draw Shokti`.

---

### Task 6: Corner invite, timer card, and thank-you

**Files:**
- Create: `Sources/SathiUI/Features/Gym/GymInvite.swift`, `Features/Gym/GymTimerCard.swift`, `Features/Celebrate/GymThanks.swift`, `Constants/UIMetrics+Gym.swift`
- Modify: `Features/Bubble/BubbleView.swift`, `Windows/UIController.swift` (`bubblePanel`, `sessionView`), `Windows/UIController+Corner.swift` (session and celebration in the corner), `Features/Celebrate/CelebrateView.swift`
- Test: `Tests/SathiUITests/GymInviteTests.swift`, `GymTimerCardTests.swift`, `GymThanksTests.swift`

**Interfaces:**
- Consumes: `Engine.gymWorkout`, `nextGymIdea()`, `notNow(_:)`, `snooze(_:)`, `startSession(.gym)`, `finishSession(.gym)`, `stopSession(.gym)`, `Copywriter.gymInviteHint`, `Copywriter.gymTimerLine`.
- Produces: `GymInvite(level: Level)`, `GymTimerCard()`, `GymThanks()`.

Layout: copy `ReadingInvite` and `ReadingTimerPill`, with the `CornerCard` modifier, the Night tokens, and the approved demo.

- [ ] **Step 1: Write the failing tests**

```swift
@Test func inviteShowsLabelAndWorkoutHint()
@Test func startButtonStartsTheGymSession()
@Test func nextIdeaButtonCallsNextGymIdea()
@Test func snoozeButtonUsesTheGeneralLabel()
@Test func closeButtonIsNotNowAtNudgeOnly()
@Test func timerShowsWorkoutNameAndDoneCounts()
@Test func timerStopDoesNotCount()
@Test func thanksNamesShokti()
```

- `inviteShowsLabelAndWorkoutHint`: text "SHOKTI · GYM" and "Neck and shoulder stretch · 5 min".
- `startButtonStartsTheGymSession`: tap "Start"; `h.engine.session(.gym) != nil`.
- `nextIdeaButtonCallsNextGymIdea`: tap "Next idea"; `h.engine.gymIdea == 1`.
- `snoozeButtonUsesTheGeneralLabel`: a button with `h.engine.snoozeShortLabel`.
- `closeButtonIsNotNowAtNudgeOnly`: at `.nudge`, tap "Dismiss"; `state(.gym).nextDue` = now + 60 min. At `.persist` no "Dismiss" button.
- `timerShowsWorkoutNameAndDoneCounts`: start the session, build `GymTimerCard`. A text "SHOKTI · Neck and shoulder stretch" shows. Tap "Done"; last event `.done(.gym, 1, …)`.
- `timerStopDoesNotCount`: tap "Stop"; no `.done` event.

- [ ] **Step 2: Run** `./scripts/test.sh SathiUITests`. Expected: FAIL, `cannot find 'GymInvite' in scope`.
- [ ] **Step 3: Implement** the 3 views. Route `.gym` in `BubbleView`, `bubblePanel` (`presentCorner(GymInvite(level: level))`), the corner session and the corner celebration. At Nudgy: one ping, then a silent wiggle (copy `ReadingInvite.shakeWhilePersisting`).
- [ ] **Step 4: Run** `./scripts/test.sh`. Expected: PASS.
- [ ] **Step 5: Ask the user, then commit** `feat(ui): Gym corner invite, timer, and thanks`.

---

### Task 7: Settings tab and Add a buddy tab

**Files:**
- Create: `Sources/SathiUI/Features/Gym/GymSettingsTab.swift`, `Features/Gym/GymRhythmCard.swift`, `Features/Gym/GymWorkoutsCard.swift`, `Features/Gym/GymWorkoutRow.swift`
- Modify: `Features/Settings/SettingsView.swift`, `SettingsSidebar.swift` (`icon`, `isNew` true for `.gym`), `Engine+SettingsBindings.swift`, `AddBuddyTab.swift`, `HeroCopy.swift`
- Test: `Tests/SathiUITests/GymSettingsTabTests.swift`, `Tests/SathiUITests/SettingsSidebarTests.swift`

**Interfaces:**
- Consumes: `GymPrefs`, `GymPrefs.cleaned`, `Limits.gymIntervalChips`, `Limits.gymWorkoutLengths`, `Limits.gymNameMaxLength`.
- Produces: `GymSettingsTab()`; bindings `e.gymBinding(\.intervalMinutes)` style, matching the helpers in `Engine+SettingsBindings.swift`; `e.gymWorkoutName(at: Int) -> Binding<String>`, `e.gymWorkoutMinutes(at: Int) -> Binding<Int>`.

Sections, in order: hero (`SHOKTI · GYM`, "Get up, little and often", hint "Shokti suggests a short move while you work.", switch); RHYTHM (Remind me every, Work hours with "Shokti sleeps outside these hours.", Work days); MY 4 WORKOUTS (4 rows: number, name field, minutes chips); IF I IGNORE SHOKTI (Gentle and Nudgy only, copy the Reading tab).

- [ ] **Step 1: Write the failing tests**

```swift
@Test func tabShowsHeroRhythmWorkoutsAndTwoStrictnessCards()
@Test func intervalChipsAreFortyFiveSixtyNinety()
@Test func editingANameSavesACleanedName()
@Test func clearingANameSavesTheDefaultName()
@Test func minutesChipSavesTheChoice()
@Test func lastWorkDayCannotBeTurnedOff()
@Test func sidebarShowsGymWithNewLabel()
@Test func addBuddyTabShowsTwoComingSoonBuddies()
```

- `editingANameSavesACleanedName`: set the row 2 binding to a 60-character string; `h.store.prefs.gym.workouts[1].name.count == 40`.
- `clearingANameSavesTheDefaultName`: set row 1 to `""`; saved name is "Neck and shoulder stretch".
- `addBuddyTabShowsTwoComingSoonBuddies`: replaces `addBuddyTabShowsFourComingSoonBuddies`. Texts "Eye break" and "Posture" show; "Stretch" and "Walk" do not; 2 "Soon" buttons. Explain the change in the commit message: Gym now covers Stretch and Walk (spec, "Add a buddy tab").

- [ ] **Step 2: Run** `./scripts/test.sh SathiUITests`. Expected: FAIL, `cannot find 'GymSettingsTab' in scope`.
- [ ] **Step 3: Implement.** The name field saves on each change through `GymPrefs.cleaned`, so a cleared field shows the default name after the save. Keep each file under 200 lines.
- [ ] **Step 4: Run** `./scripts/test.sh`. Expected: PASS.
- [ ] **Step 5: Ask the user, then commit** `feat(ui): Gym settings tab`.

---

### Task 8: Menu, reports, checks, and docs

**Files:**
- Modify: `Sources/SathiUI/Features/MenuBar/HabitCard.swift` (Gym row: next reminder time, a Start button that calls `startSession(.gym)`)
- Modify: `CLAUDE.md` (module map: `Gym/` in `Habits/`, `Features/Gym/`; intro line names Shokti), `README.md`, `docs/ROADMAP.md`
- Test: `Tests/SathiUITests/HabitCardTests.swift` (or the existing menu test file), `Tests/SathiCoreTests/EngineReportScreenTests.swift`

- [ ] **Step 1: Write the failing tests**: the menu shows a Gym card when Gym is on and none when it is off; the reports tile for Gym shows unit "workouts" and goal 4; 4 done workouts shade the calendar day as "goal met".
- [ ] **Step 2: Run** `./scripts/test.sh`. Expected: the new tests fail.
- [ ] **Step 3: Implement**, then update the docs.
- [ ] **Step 4: Run the Definition of done**

1. `./scripts/test.sh`. Expected: all pass. Report the real count.
2. `./scripts/lint.sh`. Expected: no errors, no file over 200 lines.
3. `swift build -c release`. Expected: no new warnings.
4. `./build.sh --install`, wait 10 s, `./scripts/perf.sh`. Expected: idle CPU < 1%, memory < 40 MB, wakeups < 10/min. Then run it again during a Gym timer and after it ends: CPU goes back to ~0%.
5. Ask the user to run `./scripts/perf.sh --windows` in Terminal.
6. Run the `ui-verifier` agent with `.superpowers/brainstorm/33898-1793029157/content/gym-demo-v2.html` as the reference.

- [ ] **Step 5: Ask the user, then commit** `feat: Gym (Shokti) menu card, reports, and docs`
- [ ] **Step 6:** Run `/sathi-website` for the site text and screenshots. Ask before each commit and before any push.
