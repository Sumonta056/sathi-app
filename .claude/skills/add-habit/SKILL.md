---
name: add-habit
description: Add a new habit buddy to Sathi (for example stretch, eye break, walk). Use when the user types /add-habit <name> or asks for a new reminder type. Lists every file that must change, in order, with the tests for each step.
---

# /add-habit: add a new reminder habit

Input: `$ARGUMENTS` is the habit: name, buddy name, schedule, and what "done" means.

Run the `/feature` loop (`.claude/skills/feature/SKILL.md`). Use the steps below as the plan for its step 2. Write the tests of each step first (its step 3).

## Words in this file

- `<Name>`: the habit in UpperCamelCase (`Stretch`). `<name>`: lowerCamelCase (`stretch`).
- Short paths start at `Sources/SathiCore/` (Core steps) or `Sources/SathiUI/` (UI steps).
- `<Kind>`: the new `BuddyKind` case, in UpperCamelCase (`Twig`). Water is `drop`, Reading is `book`, Meditation is `pebble`.

## 0. Decide the kind of habit

Ask the user with AskUserQuestion. Each kind has a model habit. Copy the model in every later step.

| Kind | Example | Model | Core model code |
|---|---|---|---|
| A. Interval, done by a tap | stretch, eye break | Water | `Habits/Water/WaterRules.swift` (`nextDue`, `isActiveTime`), `logWater` in `Engine/Engine+Actions.swift` |
| B. Once a day, timed session | walk, journal | Reading | `Habits/Reading/ReadingRules.swift`, `startSession` and `finishSession` in `Engine/Engine+Session.swift` |
| C. Time slots, timed session | posture check | Meditation | `Habits/Meditation/MeditationRules.swift`, `Engine/Engine+Session.swift` |

Also ask:

1. Active hours (kind A). Only `WaterPrefs.startMinutes` and `endMinutes` exist. `GeneralPrefs` has none. Reuse the Water hours, or add own fields to `<Name>Prefs`?
2. Daily goal and unit. What does `HabitRules.dailyGoal` return? What does the report tile show (count, min)?
3. Calm or strict. May the habit lock the screen? The default answer is no.

## 1. Business rules

Edit `.claude/rules/business-logic.md` before any code.

1. "Words" table: add the buddy name.
2. "Schedules" table: add the schedule and "Done when".
3. Escalation rule 1 names the habits that never lock. Add the new habit, or change the rule if it may lock.
4. A calm habit gets a rule like Escalation rule 5: the invite never takes focus, Nudgy wiggles in silence, snooze uses the General length.
5. Goal: Schedules rule 7 says a goal of 0 never counts as met. Then the streak stays 0. "Stats and reports" rule 5 caps "% of goal" at 100.

## 2. Core model

| File (under `Sources/SathiCore/`) | Change |
|---|---|
| `Models/HabitID.swift` | Add the case. Add its `name` and `buddy`. |
| `Habits/<Name>/<Name>Prefs.swift` | Copy `Habits/Meditation/MeditationPrefs.swift`. Set `enabled = false`. |
| `Models/Prefs.swift` | Add `<name>` to `Prefs`, `init(from:)`, `scheduleKey`, `isEnabled`, and `strictness`. |
| `Models/Persisted.swift` | `lastDone`: read the last `.done` event, like `.meditation`. Add no `LiveState` field. |
| `Constants/Limits.swift` | Ranges and choices (like `meditationLengths`). |
| `Constants/Timing.swift` | Only if the habit needs new durations (like `breathBox`). |

1. Default the habit to off. An update never starts a reminder the user did not ask for.
2. Decode each field with the helpers in `Models/DecodingDefaults.swift`: `value(_:or:)`, `known(_:or:)`, `knownSet(_:or:keepsEmpty:)`.
3. Put each field that moves the due time in `scheduleKey`. Own active hours are such fields.
4. Use `withoutLock` in `strictness` if the habit never locks.
5. Never change a raw value once it ships (Escalation rule 4).

Tests: copy `Tests/SathiCoreTests/MeditationPrefsTests.swift` (suite "Meditation prefs") to `<Name>PrefsTests.swift`. Test defaults, old JSON without the field, round trip, and `scheduleKey`. Add unknown raw values to `LenientPrefsDecodingTests.swift`.

## 3. Core rules

1. Add `Habits/<Name>/<Name>Rules.swift`. Copy the model rules of your kind. Conform to `HabitRules`.
2. Use `DayClock` for wall-clock times. Read the calendar from the init. Never use `Date()`.
3. Set `dailyGoal`. Kind A copies `WaterRules.dailyGoal`. Kinds B and C use session minutes.
4. Put helper types in the same folder (like `Habits/Meditation/BreathingPattern.swift`).
5. Register the rules in `HabitID.rules(_:calendar:)` in `Habits/HabitRules.swift`.

Tests: `<Name>RulesTests.swift`. Copy `WaterRulesTests.swift` (kind A) or `MeditationRulesTests.swift` (kinds B, C). Add a DST case like `DayClockDSTTests.swift`.

## 4. Copy

1. `Formatting/Copywriter.swift`: add the celebration titles, and the nudge and persist lines in the private `choices` switch.
2. Put other helper copy (invite hint, thanks hint) in a new `Formatting/Copywriter+<Name>.swift`, like `Copywriter+Meditation.swift`.

Tests: `<Name>CopyTests.swift` (copy `MeditationCopyTests.swift`).

## 5. Done action (kind A only)

Kinds B and C use `startSession` and `finishSession`. Skip this step for them.

1. Add `mark<Name>()` (for example `markStretched()`). Model it on `logWater` in `Engine/Engine+Actions.swift`.
2. `Engine+Actions.swift` is 135 lines. Put the action in a new `Engine/Engine+<Name>.swift`, so no file passes 200 lines.
3. The action does this, in order:
   1. `record(.done(.<name>, 1, at: n))` with `n = clock.now`.
   2. `habits[.<name>] = HabitState(nextDue: freshDue(.<name>, lastDone: n))`.
   3. Remove `.<name>` from `queue`.
   4. If `isActive(.<name>)`: `presenter.closeBubble()`, `presenter.closeLock()`, set `phase = .idle`.
   5. If `phase == .idle`: `celebrate(.<name>, 1)`.
   6. `requestTick()`.

Tests: `Engine<Name>Tests.swift` with `EngineHarness`. Check the done event, the new due time, the empty queue, `h.presenter.calls`, and the celebration.

## 6. Build and fix every switch

1. Run `swift build`. Fix the errors in `SathiCore` first. Never add `default:`.
2. `SathiUI` errors show only after `SathiCore` compiles. Run `swift build` again and fix them.
3. Use these lists as a check. The compiler is the source of truth.

Core (`Sources/SathiCore/`). A scratch build with a new case fails in these 10 files:

- `Models/HabitID.swift`, `Models/Prefs.swift`, `Models/Persisted.swift`, `Stats/ReportScreenBuilder+Tiles.swift`
- `Engine/Engine+Actions.swift`, `Engine+Corner.swift`, `Engine+Display.swift`, `Engine+Loop.swift`, `Engine+Menu.swift`, `Engine+Session.swift`

`Habits/HabitRules.swift` and `Formatting/Copywriter.swift` also switch on `HabitID`. Steps 3 and 4 change them first, so they compile.

UI (`Sources/SathiUI/`):

- `Buddy/BuddyKind.swift`, `Theme/NightPalette.swift`, `Theme/ShakeSound.swift`
- `Windows/UIController.swift`, `Windows/UIController+Corner.swift`
- `Features/Bubble/BubbleView.swift`, `Features/Bubble/LegacyBubble.swift`
- `Features/Celebrate/CelebrateView.swift`, `Features/Celebrate/LegacyCelebrate.swift`
- `Features/Lock/LockView.swift`, `Features/MenuBar/HabitCard.swift`, `Features/Session/SessionCopy.swift`
- `Features/Settings/Engine+SettingsBindings.swift`, `SettingsSidebar.swift`, `SettingsView.swift`

What to return in the session and lock switches:

| Place | Kind A (no session, like `.water`) | Kinds B, C (session) |
|---|---|---|
| `lockConfirmed(_:)` in `Engine+Actions.swift` | `mark<Name>()` from step 5 | `startSession(.<name>)`, like `startReading()` |
| `sessionMinutes(_:)` in `Engine+Session.swift` | `nil` | the prefs session minutes |
| `startSound(_:)` in `Engine+Session.swift` | `nil` | `nil`, or a `SoundName` like `.purr` |
| `celebrationSound(_:)` in `Engine+Session.swift` | `.hero` | `.hero`, or a chime like `.tink` |
| `SessionCopy.title`, `body`, `breath` | like `.water`: a short title, `""`, `nil` | a title, a body line, `nil` |
| `UIController.sessionView(_:)` | join the `.water, .reading` case (never shown) | `SessionView()` (join `.water, .reading`), or an own view like `BreatheView()` |
| `LockView` `headline`, `instructions` | a real line | a real line |

`LockView` lines are `String`, not optional. Reading and Meditation never lock, but they have lines.

Checks that are not a switch. The compiler never flags them. Find them with this command:

```
grep -rnE "[=!]= \.(water|reading|meditation)\b|contains\(\.(water|reading|meditation)\)" Sources
```

Today it finds these hits that matter:

- `Engine/Engine+Display.swift:109`: `isBook: focus == .reading` in `updateStatus()` feeds `StatusModel.isBook`. `StatusLabel` then shows a book icon, else the water glass. Ask the user which menu bar icon the new habit shows.
- `Buddy/BuddyCanvas.swift:63`: `kind == .pebble` picks the closed eyes. See step 7.
- `Features/Session/SessionView.swift:36` and `Features/Meditation/BreatheView.swift:12`: `e.queue.contains(.water)` shows the "queued" banner only for Water. See step 7.
- Leave the hits in `Persisted.swift` and in `logWater`. They belong to one habit.

Tests: copy `EngineMeditationTests.swift` ("Engine meditation") and `EngineMeditationDisplayTests.swift` ("Engine meditation display"). Use `EngineHarness`. `EngineFlowTests.swift` ("Engine flows") must still pass.

## 7. UI

| File (under `Sources/SathiUI/`) | Change |
|---|---|
| `Buddy/BuddyKind.swift` | New `<Kind>` case. |
| `Buddy/BuddyCanvas.swift` | Draw call in the `switch kind`. Decide the eyes at line 63: `kind == .pebble` is not a switch. |
| `Buddy/BuddyCanvas+<Kind>.swift` | The drawing. Copy only the `drawPebble` function from `BuddyCanvas+Pebble.swift`. |
| `Buddy/BuddyCanvas+Pebble.swift` | Add the case to the shared `faceInk` and `cheekFill`. Do not copy them, or Swift reports a redeclaration. |
| `Theme/NightPalette.swift` | Accent color. Add it to `Night.accent`, `heroFill`, `heroBorder`. |
| `Features/<Name>/<Name>SettingsTab.swift` | Copy `Features/Meditation/MeditationSettingsTab.swift`. |
| `Features/Settings/SettingsView.swift` | Show the tab for `.habit(.<name>)`. |
| `Features/Settings/SettingsSidebar.swift` | `icon(_:)` and `isNew(_:)`. |
| `Features/<Name>/<Name>Invite.swift` | The reminder view. Copy `Features/Meditation/MeditationInvite.swift`. |
| `Features/Celebrate/<Name>Thanks.swift` | The thank-you card. Copy `MeditationThanks.swift`. |
| `Constants/UIMetrics+<Name>.swift` | Sizes. Copy `UIMetrics+Meditation.swift`. |

1. Route the reminder. `BubbleView` returns `<Name>Invite(level:)`. In `UIController.bubblePanel`, a calm habit uses `presentCorner(BubbleView(id: id, level: level))`, like `.meditation`. A corner panel never takes focus.
2. The main button of `<Name>Invite` calls the done action: `mark<Name>()` (kind A) or `startSession(.<name>)`. The second button calls `snooze()`.
3. Route the thank-you in `CelebrateView` and in `celebrationPanel` (`Windows/UIController+Corner.swift`).
4. Kind A: call `mark<Name>()` from `HabitCard` (`Features/MenuBar/HabitCard.swift`).
5. Queued banner: `SessionView.swift:36` and `BreatheView.swift:12` check only `.water`. A queued kind A habit should get a banner too.
6. Loop animations use `TimelineView`, cap at 30 fps, and pause when hidden.

Tests (`Tests/SathiUITests/`): copy `MeditationSettingsTabTests.swift`, `MeditationInviteTests.swift`, `MeditationThanksTests.swift`, and `MeditationViewTests.swift`. Add a tap test on the main button that checks the Engine action.

## 8. Storage

1. Read `.claude/rules/storage.md`.
2. Follow the `data-migration` skill (`.claude/skills/data-migration/SKILL.md`), recipe "Add a field".
3. Old `prefs.json` files without `<name>` must decode. The other settings must stay.
4. A new `HabitID` case is a new value in `history/YYYY-MM.json`. Read the downgrade warning in that skill.

## 9. Add Buddy tab

1. If `AddBuddyTab.rows` in `Features/Settings/AddBuddyTab.swift` has a "Soon" card for the habit, remove it.
2. Rebuild the rows from the cards that stay. A row may hold 1 card.
3. Update `addBuddyTabShowsFourComingSoonBuddies` in `Tests/SathiUITests/SettingsSidebarTests.swift`. Update its text list (it finds "Stretch") and its count of 4 "Soon" buttons.

## 10. Fix tests with fixed habit lists

1. Find them: `grep -rnE "HabitID\.allCases|\[HabitID\.|\[\.water, \.reading" Tests`.
2. Tests that loop over `HabitID.allCases` need no change. Fix each fixed list. Known ones:
   - `Tests/SathiCoreTests/MeditationPrefsTests.swift`: `HabitID.allCases == [.water, .reading, .meditation]`.
   - `Tests/SathiCoreTests/WaterThanksCopyTests.swift`: `@Test(arguments: [HabitID.reading, .meditation])`.
   - `Tests/SathiUITests/ShakeSoundTests.swift`: `@Test(arguments: [HabitID.reading, .meditation])`.
3. Explain each test change in the plan. Never weaken a test.

## 11. Finish

1. Run the checks in `CLAUDE.md`, "Definition of done": `./scripts/test.sh`, `./scripts/lint.sh`, `swift build -c release`.
2. Run `/perf-check` if the reminder view or the buddy animates.
3. `CLAUDE.md`: add the folder to the `Habits/` line of the module map.
4. `README.md`: the buddy list names only Fota and Boi. Add the new buddy, and Shanti if it is still missing.
5. Return to the `/feature` loop for review. Ask before `git commit`.
