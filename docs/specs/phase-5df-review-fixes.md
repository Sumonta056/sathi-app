# Phase 5d/5f review fixes

Source: shared review of 5d and 5f (2026-10-25). User decisions: cap the animations now; the meditation invite never takes focus; the "See you" text for pause and water off; accept the last partial breathing round (Later list).

Rules: `CLAUDE.md` rule 7 (animations cap at 30 fps and pause when hidden), `.claude/rules/business-logic.md` Escalation rules 5 and 6.

## F1. Cap every loop animation at 30 fps (M1, m1, m2, m4)

No `withAnimation`, `.repeatForever`, or long `.linear` animation for loops or bars. Each looping view uses one `TimelineView` and a pure static function of time. Pause the timeline when the view is hidden (`onAppear`/`onDisappear` flag, as in `BuddyView`) and when `accessibilityReduceMotion` is on.

| View | Timeline | Pure function (internal, tested) | Reduce Motion |
|---|---|---|---|
| `BobbingBuddy` | `.animation(minimumInterval: UIMetrics.animationFrameInterval, paused:)` | `static func offset(at t: TimeInterval) -> CGFloat`: `-bobHeight * (1 - cos(2π t / (2 · bobDuration))) / 2`. t = 0 → 0; t = bobDuration → -bobHeight; t = 2 · bobDuration → 0. | offset 0 |
| `SparkBurst` | same | `static func phase(at t: TimeInterval) -> (scale: CGFloat, opacity: Double)` over a `sparkDuration` loop: opacity 0 → 1 at 40 % → 0 at 100 %; scale 0.4 → 1.4 linear. | static, scale 1, opacity 1 |
| `IgnoreBar` | `.periodic(from: .now, by: UIMetrics.ignoreBarRefresh)` (0.5 s, constant comes back) | `static func fraction(deadline: Date, now: Date, total: TimeInterval) -> Double`: `clamp((deadline - now) / total, 0, 1)`; total ≤ 0 → 0. | same steps (a step every 0.5 s is not motion) |
| `BreathCircle` | `.animation(minimumInterval:, paused:)` | `static func scale(_ style: BreathingStyle, elapsed: TimeInterval) -> CGFloat`: with `step = BreathingPattern.step(style, at: elapsed)` and `p = 1 - step.remaining / phaseDuration`, eased with `(1 - cos(π p)) / 2`: inhale small → big, hold big, exhale big → small, rest small. Halo opacity follows the same curve between `breathHaloSmall` and `breathHaloBig`. | `breathScaleBig`, no change |

`BreathCircle` takes `style` and `start: Date` (session start) and computes `elapsed` from the timeline date, so the circle is smooth and exact at phase edges. The text in `BreatheView` still comes from `e.now` (1 s tick). Keep `BreathCircle.scale(for:)` (test 16 of 5f).

`IgnoreBar` drops the `@State progress` and `onAppear` animation.

## F2. Meditation invite never takes focus (M2)

`UIController.showBubble`: exhaustive switch on the habit. Water: today's path (`presentTopRight` + `makeKey`). Reading: corner (5e) or legacy bubble with `makeKey` for focus style. Meditation: `CornerToast.make` + `placeTopRight`, no `makeKey`. Put the choice in one private helper.

## F3. "See you" text (m5)

`Engine.waterSeeYou`: water off (`!enabled(.water)`) → "Nice one"; `pausedUntil != nil` → "See you after your break"; else as today. Order: off first, then paused.

## F4. Panels do not grow upward (m3)

In `UIController.hosting`, set `h.sizingOptions = []` (macOS 13+), so the panel keeps its first size. Make content heights stable:

- `WaterLogArea`: fixed height `UIMetrics.waterLogHeight` = the taller of the bottle row and the amount cards (150).
- `BreatheView`: the "Fota is waiting…" line always takes its space; hide it with `opacity(0)` and `accessibilityHidden(true)` when water is not queued (the test that checks its absence must still pass: if ViewInspector still finds the hidden text, use a fixed-height empty frame instead).

## F5. Shake sound is a tested rule (m6)

`enum ShakeSound { static func sound(for id: HabitID) -> SoundName? }`: water → `.tink`; reading → nil; meditation → nil (exhaustive). `WaterBubble`, `ReadingInvite`, `MeditationInvite`, and `LegacyBubble` call `if let s = ShakeSound.sound(for: id) { e.play(s) }` in their shake loop.

`LegacyBubble`: replace the repeating `Timer.publish` with the same `.task(id: level)` loop (n6).

## F6. Small fixes

- `WaterBottleRow`: start `bottleNow` with `@State(initialValue:)` from the parent's `bottleLevel` (n1).
- `WaterThanks`/`DropsRow`: goal drops = `Int(dailyGoalGlasses.rounded(.up))`, at least 1 (n2).
- `MeditationInvite`: remove the outer halo circle; the Shanti drawing has its own (n3).

## Later (not in this fix)

- Breathing sessions end mid-cycle; the last ~12 s repeat the last round (user: accept for now).
- `BreatheView` reads the breathing style live; a style change mid-session jumps the phase (store the style at session start).

## Tests that define done

Core:

1. `waterSeeYou` with water off → "Nice one".
2. `waterSeeYou` while paused (`pause(hours: 1)` after `logWater(1)`) → "See you after your break".
3. `waterSeeYou` with water off and paused → "Nice one".
4. Existing `waterSeeYou` tests still pass.

UI (pure functions and views):

5. `BobbingBuddy.offset(at:)`: 0 → 0; `bobDuration` → `-bobHeight`; `2 · bobDuration` → 0 (tolerance 0.0001).
6. `SparkBurst.phase(at:)`: t = 0 → opacity 0, scale 0.4; t = 0.4 · sparkDuration → opacity 1; t just below `sparkDuration` → opacity near 0, scale near 1.4.
7. `IgnoreBar.fraction`: deadline 5 min ahead, total 5 min → 1; 2.5 min ahead → 0.5; deadline in the past → 0; total 0 → 0.
8. `BreathCircle.scale(.box, elapsed:)`: 0 → small; 2 → midway ((small + big) / 2); 4 → big; 6 → big (hold); 10 → midway (exhale); 12 → small; 14 → small (rest); 16 → small (next inhale starts).
9. `BreathCircle.scale(.even, elapsed: 2.5)` → midway; `(.relax, elapsed: 4 + 7 + 4)` → midway of the exhale.
10. `ShakeSound.sound(for:)`: water → `.tink`; reading → nil; meditation → nil.
11. `BreatheView` with `.relax`, 5 min, elapsed 0 → "WIND DOWN · 4·7·8", "Breathe in", "Round 1 of 15".
12. `BreatheView` with `.even`, 5 min, elapsed 6 → "Breathe out", "Round 1 of 30".
13. `DropsRow` with goal 7.5 → 8 drops.
14. All 5d, 5e, and 5f tests still pass.
