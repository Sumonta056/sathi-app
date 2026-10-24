# Phase 5f: Meditation invite, breathe view, and Shanti

Goal: rebuild the meditation reminder, the meditation session, and the meditation thank-you in the Night theme, as on the canvas, and redraw Shanti.

Rules: `.claude/rules/business-logic.md` (Escalation rule 5, Schedules rule 6). Design: https://claude.ai/artifact/AgF243uMtC5H8ySBfdXx6e (Meditation artboard). Theme: `docs/specs/phase-5a-theme.md`. Patterns to reuse: `docs/specs/phase-5d-water-bubble.md` (`BobbingBuddy`, card), `docs/specs/phase-5e-reading-corner.md` (`snoozeShortLabel`, silent wiggle).

User decisions (2026-10-25):

- The session button is "Stop". An early stop does not count (Schedules rule 6, unchanged).
- The invite snooze button is `e.snoozeShortLabel` ("In 5 min"), not "Later".
- At Nudgy the invite wiggles in silence (no repeat sound).

## Part 1: Core

### `BreathingPattern.totalRounds(_ style: BreathingStyle, minutes: Int) -> Int`

`max(1, Int((Double(minutes) * Timing.minute / cycleLength(style)).rounded(.down)))`.

Examples: box (16 s), 5 min → 18; relax (19 s), 5 min → 15; even (10 s), 5 min → 30; box, 0 min → 1.

### `BreathingPattern.round(_ style: BreathingStyle, elapsed: TimeInterval, minutes: Int) -> Int`

`min(step(style, at: elapsed).cycle + 1, totalRounds(style, minutes: minutes))`. Elapsed 0 → 1; box elapsed 16 → 2; box elapsed 10 000, 5 min → 18.

### `Copywriter.meditationInviteHint(minutes: Int, style: BreathingStyle) -> String`

"{minutes} minutes of {name}. Shanti counts for you." 1 minute → "1 minute of …". Names: box → "box breathing", relax → "wind-down breathing", even → "even breathing".

### `Copywriter.breathHeader(_ style: BreathingStyle) -> String`

"{NAME} · {beats}", with NAME: box → "BOX BREATHING", relax → "WIND DOWN", even → "EVEN BREATHING"; beats = the step durations as whole numbers joined by "·" (box → "4·4·4·4", relax → "4·7·8", even → "5·5").

### `Copywriter.breathRound(_ round: Int, of total: Int) -> String`

"Round {round} of {total}".

### `Copywriter.calmThanksHint(streak: Int) -> String`

streak ≥ 2 → "{streak} calm days in a row."; otherwise "A calm start."

Move `SessionCopy.label(_ phase:)` ("Breathe in", "Hold", "Breathe out", "Rest") to `Copywriter.breathLabel(_:)` in Core if it helps the tests; keep `SessionCopy` working.

## Part 2: UI

`Night` colors, `Typography`, constants in new `UIMetrics+Meditation.swift`. Views set `.environment(\.colorScheme, .dark)`. Calm card: fill `Night.calmGround`, border `Night.heroBorder(.meditation)` 1 pt (at `.persist` `Night.calm` 2 pt), radius 24, padding 24, shadow like `WaterCard`.

### `BubbleView` dispatch

`.meditation` → `MeditationInvite(level:)`. (`.reading` stays `LegacyBubble` for the focus style.) Placement stays as the existing bubble path (top-right).

### `MeditationInvite(level:)` (`Features/Meditation/MeditationInvite.swift`)

Width `UIMetrics.calmCardWidth` (400). Centered `VStack`, spacing 14:

1. Eyebrow "SHANTI · MEDITATION" (`Typography.eyebrow`, `Night.calm`).
2. `BobbingBuddy(habit: .meditation, size: UIMetrics.calmInviteBuddySize)` (150) on a faint `Night.calm` 0.12 circle.
3. Title `e.copy.title` (`Typography.bubbleTitle`).
4. Hint `Copywriter.meditationInviteHint(minutes: sessionMinutes, style: style)` (`hint`, `Night.muted`, centered, max width 280).
5. At `.persist`: `e.warnText(.meditation)` hint.
6. Buttons row: "Breathe with me" (accent, `Night.calm` fill, `Night.calmGround` text, fills the width, height 40) → `e.startMeditation()`; `e.snoozeShortLabel` (ghost, border `heroBorder(.meditation)`) → `e.snooze()`.

At `.persist`: silent wiggle every `UIMetrics.shakeInterval` (same `.task(id: level)` pattern as `ReadingInvite`, no sound).

### `UIController.showSession`

Meditation → `BreatheView()` centered (as today, but the new view). Reading → corner pill or `SessionView` (5e, unchanged). Exhaustive switch.

### `BreatheView` (`Features/Meditation/BreatheView.swift`)

Width 400, calm card. `elapsed = max(0, e.now - e.sessionStart)` (Engine ticks every 1 s during a session; no `TimelineView`, no timer). `step = BreathingPattern.step(style, at: elapsed)`.

1. Header `Copywriter.breathHeader(style)` (`Typography.eyebrow`, `Night.calm`).
2. `BreathCircle(phase: step.phase, duration: <phase duration>)`, 260 pt:
   - A halo circle (`Night.calm`, radius 110/260 of the frame) and a glow circle (`Night.calm` 0.9 opacity, radius 96/260).
   - Target scale: `BreathCircle.scale(for: phase)`: `.inhale`, `.hold` → `UIMetrics.breathScaleBig` (1); `.exhale`, `.rest` → `UIMetrics.breathScaleSmall` (0.62). Halo opacity big 0.4, small 0.15.
   - Animate with `.easeInOut(duration: duration of the current phase)` when `phase` changes (`.animation(_:value: phase)`). Reduce Motion: no animation, fixed scale at `breathScaleBig`.
   - Shanti's closed-eye face in the center (`BuddyCanvas` face only, or a small `StaticBuddy` at 70).
3. Phase text `Copywriter.breathLabel(step.phase)` (24 pt black → `Typography.breathPhase`).
4. `Copywriter.breathRound(BreathingPattern.round(style, elapsed:, minutes:), of: totalRounds)` (`hint`).
5. Button "Stop" (ghost) → `e.stopSession()`.

When water is queued, show "Fota is waiting for you after this" (`hint`, `Night.water`) as the old `SessionView` did.

### `MeditationThanks` (`Features/Celebrate/MeditationThanks.swift`)

`CelebrateView`: `.meditation` → `MeditationThanks()`. Calm card, width 400, centered content: `BobbingBuddy(habit: .meditation, size: 120)`, title `e.celebration.title` (`Typography.thanksTitle`), hint `Copywriter.calmThanksHint(streak: e.streak(.meditation))`, accent button "Back to work" (`Night.calm` fill) → `e.endCelebrate()`. Placement stays centered.

### Shanti drawing (`Buddy/BuddyCanvas+Pebble.swift`)

Redraw `drawPebble` to match the canvas: a round body in `Night.calm`, a faint halo (`Night.calm` 0.12), a green sprout (`Night.sprout` leaf with a lighter second leaf), the closed-eye arcs and a small smile (existing face code; ink `Night.calmGround` for the pebble face), cheeks `Night.cheek` 0.85. Keep the same 100×124 coordinate space and the `BuddyCanvas` API. The settings hero, the menu ring, and every other place that draws Shanti get the new look.

### Delete

Nothing yet. `SessionView` stays for the reading focus style. `LegacyCelebrate` keeps its meditation branch unused (5g removes the old palette).

### Constants (`UIMetrics+Meditation.swift`)

`calmCardWidth` 400, `calmPadding` 24, `calmSpacing` 14, `calmRadius` 24, `calmInviteBuddySize` 150, `calmHaloOpacity` 0.12, `calmHintWidth` 280, `calmButtonHeight` 40, `breathCircleSize` 260, `breathHaloRatio` 110/130, `breathGlowRatio` 96/130, `breathScaleBig` 1, `breathScaleSmall` 0.62, `breathHaloBig` 0.4, `breathHaloSmall` 0.15, `breathFaceSize` 70, `calmThanksBuddySize` 120, `fontBreathPhase` 24. `Typography.breathPhase`.

## Tests that define done

Core:

1. `totalRounds`: box 5 → 18; relax 5 → 15; even 5 → 30; box 0 → 1.
2. `round`: box elapsed 0 → 1; 15.9 → 1; 16 → 2; 10 000 with 5 min → 18.
3. `meditationInviteHint(minutes: 5, style: .box)` → "5 minutes of box breathing. Shanti counts for you."; `(1, .even)` → "1 minute of even breathing. Shanti counts for you."; `(10, .relax)` → "10 minutes of wind-down breathing. Shanti counts for you."
4. `breathHeader`: box → "BOX BREATHING · 4·4·4·4"; relax → "WIND DOWN · 4·7·8"; even → "EVEN BREATHING · 5·5".
5. `breathRound(3, of: 18)` → "Round 3 of 18".
6. `calmThanksHint`: 4 → "4 calm days in a row."; 1 and 0 → "A calm start."
7. `breathLabel`: inhale "Breathe in", hold "Hold", exhale "Breathe out", rest "Rest".

UI:

8. `BubbleView(id: .meditation, level: .nudge)` contains `MeditationInvite`, "SHANTI · MEDITATION", `e.copy.title`, the hint, "Breathe with me", "In 5 min".
9. Tap "Breathe with me" → phase `.session(.meditation)`.
10. Tap "In 5 min" → phase `.idle`, `state(.meditation).snoozes == 1`.
11. `.persist` shows `e.warnText(.meditation)`.
12. `BreatheView` right after `startMeditation()` (box, 5 min) shows "BOX BREATHING · 4·4·4·4", "Breathe in", "Round 1 of 18", and "Stop".
13. Box, elapsed 6 s → "Hold", "Round 1 of 18". Box, elapsed 18 s → "Breathe in", "Round 2 of 18". (Use `advance(seconds:)` if the harness has it; otherwise move the fake clock and call `tick()`.)
14. Tap "Stop" before the end → phase `.idle`, no meditation done event.
15. With water queued during the session → "Fota is waiting for you after this".
16. `BreathCircle.scale(for:)`: inhale and hold → big; exhale and rest → small.
17. `CelebrateView` after a full meditation session → `MeditationThanks`, the title, "A calm start.", button "Back to work"; tap → `.idle`.
18. Reading focus style still uses `SessionView`; existing reading tests still pass.

Update old tests that check the old meditation bubble, the old meditation session text, or the old meditation celebration (for example `MeditationViewTests.swift`). Report each change.
