# Phase 5d: Water bubble

Goal: rebuild the water reminder bubble and the water thank-you card in the Night theme, as on the canvas. Reading and Meditation bubbles keep the old look until 5e and 5f.

Rules: `.claude/rules/business-logic.md` (no rule changes). Design: https://claude.ai/artifact/AgF243uMtC5H8ySBfdXx6e (Water bubble artboard). Shared parts: `docs/specs/phase-5a-theme.md`.

User decisions (2026-10-25):

- Sip bottle mode keeps the drag-the-line bottle, "Log it", and "I refilled it". No amount cards for the bottle.
- The water thank-you card appears in the top-right bubble spot, not in the screen center.

## Part 1: Core

### `Copywriter.celebrationTitle(_ id: HabitID, amount: Double = 0) -> String`

Add the `amount` parameter with a default, so old callers still compile.

| Habit | Result |
|---|---|
| Water, `amount >= 1` | "Ahh, refreshing!" |
| Water, `amount < 1` | "Every sip counts!" |
| Reading, Meditation | Unchanged (random from the existing lists) |

`Engine.celebrate(_:_:)` passes `amount`.

### `Copywriter.seeYou(next: Date, now: Date, calendar: Calendar) -> String`

| Case | Text |
|---|---|
| `next <= now` | "See you soon" |
| `next` is on the same calendar day as `now` | "See you in " + `Fmt.interval(minutes: m)`, where `m` = whole minutes from `now` to `next`, rounded up |
| otherwise (another day, or `.distantFuture`) | "See you tomorrow" |

Examples: 30 min → "See you in 30 min"; 60 → "See you in 1 hour"; 90 → "See you in 1 h 30 min"; 29 min 10 s → "See you in 30 min".

### `Engine.waterSeeYou: String`

`Copywriter.seeYou(next: state(.water).nextDue, now: clock.now, calendar: calendar)`.

## Part 2: UI

All new types are `internal`. Use `Night` colors and `Typography` only. The new water views set `.environment(\.colorScheme, .dark)`.

### `BubbleView` (dispatcher)

```swift
struct BubbleView: View {
    let id: HabitID
    let level: Level
}
```

Exhaustive `switch id`: `.water` → `WaterBubble(level:)`; `.reading`, `.meditation` → `LegacyBubble(id:level:)`. `LegacyBubble` is the old `BubbleView` body, moved without changes to `Features/Bubble/LegacyBubble.swift`. `UIController.showBubble` does not change.

### `WaterBubble(level:)` (`Features/Bubble/WaterBubble.swift`)

Card: width `UIMetrics.waterBubbleWidth` (440), padding 22, `VStack` spacing 16, fill `Night.bg`, radius 22, border `Night.heroBorder(.water)` 1 pt. At `.persist` the border is `Night.water` 2 pt. Shadow black 0.5 opacity, radius 30, y 12. Outer padding `UIMetrics.bubbleShadowPadding`.

In order:

1. **Header** (`WaterBubbleHeader`): `BobbingBuddy(habit: .water)` at `UIMetrics.bubbleBuddySize` (78). To its right:
   - Eyebrow (`Typography.eyebrow`, `Night.water`, tracking): "WATER · {time}". At `.persist`: "STILL WAITING · SNOOZED {n}× · {time}". `time` = `e.now` formatted `.omitted` date, `.shortened` time. `n` = `e.state(.water).snoozes`.
   - Title `e.copy.title` (`Typography.bubbleTitle`, 23 pt black).
   - Hint `e.copy.body` (`Typography.hint`, `Night.muted`).
2. **Log area** (`WaterLogArea`), from the old `WaterLogSection`:
   - When the container is Glass: a 3-column row of `AmountCard`s: "A few sips" (0.25), "Half" (0.5), "Full glass" (1). Each one is a `Button` that calls `e.logWater(amount)`. Card: height 132, radius 16, fill `Night.card`, border `Night.border` 1.5 pt. The border is `Night.water` on hover. The card has a `GlassIcon(fill:ink: .night)` 36×46 and the label (14 pt black, `Night.text`). The glass fill level is the amount, except that the full glass shows `UIMetrics.fullGlassLevel` (0.92).
   - When the container is Sip bottle: the old bottle row with the same strings ("Drag the line to where your water is now.", "About {n}" / "Drag down to log", "Log it", "I refilled it") and the same `Engine` calls. `BottleView(..., ink: .night)`. Text in Night colors.
3. **Controls row**: `ContainerSegment` on the left, a spacer, and the snooze button on the right.
   - `ContainerSegment`: two buttons "Glass" and "Sip bottle" in a track (`Night.sidebar`, border `Night.border`, radius 11, padding 3). The selected button has fill `Night.border` and text `Night.text`. The other has a clear fill and text `Night.muted`. Height 30. It sets a local `@State` (start value `e.data.prefs.water.container`). It does not change prefs. Accessibility: the selected button has the `.isSelected` trait.
   - Snooze button: `GhostButton`-style, title `e.snoozeLabel(.water)`, calls `e.snooze()`. Height 36, border `Night.fieldBorder`, text `Night.chipText`.
4. **Persist warning**, only at `.persist`: lock icon (`lock.fill`, `Night.water`) and `e.warnText(.water)` (`hint`, `Night.text`). Fill `Night.heroFill(.water)`, radius 10.
5. **`IgnoreBar`** (new form, below).

Shake: only at `.persist`. Every `UIMetrics.shakeInterval` the card shakes and plays `.tink`, as today. Use `.task(id: level)` with a sleep loop that runs only when `level == .persist`. At `.nudge` there is no timer.

### `BobbingBuddy(habit:size:)` (`Buddy/BobbingBuddy.swift`)

`StaticBuddy` with a `.repeatForever(autoreverses: true)` ease-in-out offset of `UIMetrics.bobHeight` (6) over `UIMetrics.bobDuration` (1.5 s). Start the animation in `onAppear`. When `accessibilityReduceMotion` is on, there is no offset and no animation. No `TimelineView`.

### `IgnoreBar(accent:track:)` (rewrite)

- Track: capsule, height 5, fill `track`. Bar: capsule, fill `accent`, width = track width × `progress`.
- `progress` is `@State`. In `onAppear`: set it to `left / total`, then `withAnimation(.linear(duration: left)) { progress = 0 }`. `left` = `max(0, e.ignoreDeadline - e.now)`; `total` = `max(1, ignoreMinutes)` minutes. With Reduce Motion on, the bar does not animate.
- Text below (`hint`, 12 pt, `Night.muted` for water): "No answer in {n} minutes counts as a snooze." (`n` = `ignoreMinutes`; "1 minute" when it is 1).
- No `TimelineView`, no timer. Delete `UIMetrics.ignoreBarRefresh` if nothing else uses it.
- `LegacyBubble` calls `IgnoreBar(accent: accent, track: Color.black.opacity(0.08))`. `WaterBubble` calls `IgnoreBar(accent: Night.water, track: Night.border)`.

### `WaterInk` (`Buddy/WaterInk.swift`)

```swift
struct WaterInk {
    var glass: Color
    var water: Color
    var drained: Color
    var outline: Color
    var cap: Color
    static let day: WaterInk
    static let night: WaterInk
}
```

`.day` = the old `Palette` colors (`waterGlass`, `water`, `waterDrained`, `outline`, `waterDeep`). `.night`: glass `Night.heroFill(.water)`, water `Night.water`, drained `Night.water` 0.25 opacity, outline `Night.waterLine` (new token `#7FD3F5`), cap `Night.water`. `GlassIcon` and `BottleView` take `ink: WaterInk = .day`.

### `WaterThanks` (`Features/Celebrate/WaterThanks.swift`)

`CelebrateView` switches on `e.celebration.id`: `.water` → `WaterThanks()`; others → the old body (moved without changes to `LegacyCelebrate`).

Same card as `WaterBubble` (width, fill, border, radius, shadow). Content centered, spacing 14:

1. A spark burst (`Night.spark` rays, `.repeatForever` fade and scale, none with Reduce Motion) behind `BobbingBuddy(habit: .water)` at `UIMetrics.thanksBuddySize` (80). Burst size 120.
2. Title `e.celebration.title` (26 pt black → `Typography.thanksTitle`).
3. Hint: `goal.done + " " + goal.rest + " today"`, where `goal = e.goalText(.water)`. Example: "3 of 8 glasses today".
4. `DropsRow(total: e.glassesToday, goal: Int(dailyGoalGlasses))`: one drop per goal glass (at least 1), 18×22, spacing 6. Drop `i` (from 0) is `.full` when `total - i >= 1`, `.half` when `total - i >= 0.5`, else `.empty`. Colors: full `Night.water`, half `Night.water` 0.5 opacity, empty `Night.border`. Expose `static func level(_ i: Int, total: Double) -> DropLevel` (`enum DropLevel { case full, half, empty }`) for tests.
5. Button `e.waterSeeYou` (accent button: fill `Night.water`, text `Night.onAccent`, height 38, radius 12) → `e.endCelebrate()`.

The card still closes by itself after `Timing.celebrationDuration`.

### `UIController.showCelebration`

When `engine.celebration.id == .water`, place the panel like the bubble: top-right of `primary.visibleFrame` with `UIMetrics.bubbleScreenInset`. Other habits stay centered. Extract the top-right origin into one private helper that `showBubble` uses too.

### Delete

`WaterLogSection` (moved into `WaterLogArea`), `CelebrateGlassRow` (replaced by `DropsRow`).

### Constants

`UIMetrics+Bubble.swift`: `waterBubbleWidth` 440, `bubblePadding` 22, `bubbleSpacing` 16, `bubbleRadius` 22, `bubbleBuddySize` 78, `thanksBuddySize` 80, `sparkSize` 120, `amountCardHeight` 132, `amountCardRadius` 16, `glassIconSize` (36, 46), `fullGlassLevel` 0.92, `segmentHeight` 30, `snoozeHeight` 36, `ignoreBarHeight` 5, `dropSize` (18, 22), `dropSpacing` 6, `thanksButtonHeight` 38, `bobHeight` 6, `bobDuration` 1.5, `sparkDuration` 1.4, `fontBubbleTitle` 23, `fontThanksTitle` 26. `Night.waterLine` `#7FD3F5`. `Typography.bubbleTitle`, `Typography.thanksTitle`.

## Constraints from the tests (ViewInspector)

- `ContainerSegment(selection: Binding<Container>)`. `WaterBubble` owns `@State private var picked: Container?` and shows `picked ?? e.data.prefs.water.container`. Do not set the start mode in `onAppear` (ViewInspector does not run it).
- `DropsRow` draws its drops in one `ForEach`. `DropLevel` is a plain enum (top level or nested in `DropsRow`).
- Water UI content must be inside the `WaterBubble` view.

## Tests that define done

Core (`SathiCoreTests`):

1. `celebrationTitle(.water, amount: 1)` and `amount: 2` → "Ahh, refreshing!".
2. `celebrationTitle(.water, amount: 0.25)` and `0.5` → "Every sip counts!".
3. `celebrationTitle(.reading)` and `(.meditation)` are still not empty.
4. `seeYou`: 30 min later → "See you in 30 min"; 60 → "See you in 1 hour"; 90 → "See you in 1 h 30 min"; 29 min 10 s → "See you in 30 min".
5. `seeYou`: `next == now` and `next < now` → "See you soon".
6. `seeYou`: next on the next day → "See you tomorrow"; `.distantFuture` → "See you tomorrow".
7. `Engine.logWater(1)` → `celebration.title == "Ahh, refreshing!"`; `logWater(0.5)` → "Every sip counts!".
8. `Engine.waterSeeYou` after `logWater(1)` at 10:00 with a 30-minute interval inside water hours → "See you in 30 min".

UI (`SathiUITests`, ViewInspector):

9. `BubbleView(id: .water, ...)` contains a `WaterBubble`; `.reading` contains a `LegacyBubble`.
10. Water bubble shows "WATER · {time}", `e.copy.title`, and "A few sips", "Half", "Full glass".
11. Tap "Half" → last event amount 0.5 and phase `.celebrate`.
12. Tap the snooze button ("Snooze 5 min") → phase `.idle`, `snoozes == 1`.
13. `.persist` shows the "STILL WAITING · SNOOZED 1× ·" eyebrow prefix, `e.warnText(.water)`, and "Last snooze".
14. `.nudge` has no `lock.fill` image.
15. Tap "Sip bottle" → "Drag the line to where your water is now." and "I refilled it" appear, and the "Half" card is gone.
16. Prefs container `.bottle` → the bubble opens in bottle mode.
17. `IgnoreBar` text with `ignoreMinutes` 5 → "No answer in 5 minutes counts as a snooze."; with 1 → "No answer in 1 minute counts as a snooze."
18. `CelebrateView` after `logWater(1)` contains `WaterThanks`, the title, "1 of 8 glasses today" (default goal), and the button `e.waterSeeYou`. Tap it → phase `.idle`.
19. `CelebrateView` after a reading session still shows "15 min read" and `ReadingWeekRow` (legacy path).
20. `DropsRow.level`: total 2.5 → indexes 0, 1 `.full`, 2 `.half`, 3 `.empty`; total 0 → index 0 `.empty`; total 0.25 → index 0 `.empty`.
21. `DropsRow` with goal 8 draws 8 drops; goal 0 draws 1.
22. Existing reading bubble tests (`readingBubbleStartsTheTimer`) still pass.

Update or remove the old tests that check removed types (`celebrationShowsTheAmountAndCloses` checks "+1 glass" and "Back to work": move it to a reading celebration, or replace it with test 18).
