# Phase 5e: Reading corner popup

Goal: when `ReadingPrefs.reminderStyle == .corner` (the default), the reading reminder, the reading session, and the reading thank-you show in a small panel in the top-right corner that never takes focus. With `.focus`, everything stays as today (legacy bubble, centered `SessionView`, legacy celebration).

Rules: `.claude/rules/business-logic.md` (Escalation rule 2 and its sub-points, Schedules rule 6). Design: https://claude.ai/artifact/AgF243uMtC5H8ySBfdXx6e (Reading corner popup artboard). Theme: `docs/specs/phase-5a-theme.md`. Card style: `docs/specs/phase-5d-water-bubble.md`.

User decisions (2026-10-25):

- The snooze button uses the General snooze length: "In {snoozeMinutes} min". No fixed 10 minutes.
- The timer pill button is "Stop". An early stop does not count (Schedules rule 6, unchanged).
- After a snooze, the note "Boi comes back at {time}" shows for 4 s, then closes.

## Part 1: Core

### `Engine.usesCorner(_ id: HabitID) -> Bool`

Exhaustive `switch`: `.water` → false; `.reading` → `data.prefs.reading.reminderStyle == .corner`; `.meditation` → false. Put it in `Engine+Display.swift` (or a new `Engine+Corner.swift` if the file passes 200 lines).

### `ReminderPresenter.showSnoozed(_ id: HabitID, until: Date)`

New port method. `UIController` implements it. `SpyPresenter` (in `Tests/SathiTestSupport/Fakes.swift`) records it as a call, the same way as the other calls. The test-writer adds it to the spy.

`Engine.snooze()`: after `snoozeHabit(id)` and `presenter.closeBubble()`, when `usesCorner(id)`, call `presenter.showSnoozed(id, until: state(id).snoozedUntil)`. This covers the tap and the auto snooze (the ignore deadline in `tick()` calls `snooze()`). No call when `usesCorner(id)` is false.

### `Copywriter`

| Function | Result |
|---|---|
| `comesBack(_ id: HabitID, at: Date, calendar: Calendar) -> String` | "{buddy} comes back at {time}". `time` = `at` formatted with `Date.FormatStyle(date: .omitted, time: .shortened)` and `calendar.timeZone`. |
| `readingInviteHint(minutes: Int) -> String` | "{minutes} calm minutes with your book." |
| `readingDoneTitle(minutes: Int) -> String` | "Lovely, {minutes} minutes read". 1 → "Lovely, 1 minute read". |
| `readingDoneHint(streak: Int) -> String` | streak ≥ 2 → "That is {streak} days in a row."; otherwise "A good start." |

`{buddy}` is `id.buddy` (Fota, Boi, Shanti).

### `Engine` display helpers

- `snoozeShortLabel: String` → "In {general.snoozeMinutes} min".
- `comesBackText(_ id:, until: Date) -> String` → `Copywriter.comesBack(id, at: until, calendar: calendar)`.

### Constants

`Timing.cornerNoteDuration` = 4 s.

## Part 2: UI

`Night` colors, `Typography`, and constants in a new `UIMetrics+Corner.swift`. Views set `.environment(\.colorScheme, .dark)`.

### Window: `Windows/CornerToast.swift`

```swift
final class CornerPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
```

A factory `CornerToast.make(_ content: NSView) -> NSPanel`: borderless + `.nonactivatingPanel`, clear background, no shadow, level `.statusBar`, `.canJoinAllSpaces` + `.fullScreenAuxiliary`, `hidesOnDeactivate = false`, `isReleasedWhenClosed = false`, `becomesKeyOnlyIfNeeded = true`. The caller never calls `makeKey`, `makeKeyAndOrderFront`, or `NSApp.activate`. Place it top-right with the existing `presentTopRight` origin. Buttons work without key focus (non-activating panel).

### `UIController` changes

Move the corner code to `UIController+Corner.swift` if `UIController.swift` passes 200 lines.

- `showBubble(id, level)`: when `engine.usesCorner(id)` → `ReadingInvite(level:)` in a `CornerToast` (stored in `bubble`). Otherwise as today (and `makeKey` only on that path).
- `showSession()`: when `engine.sessionHabit` uses the corner → `ReadingTimerPill()` in a `CornerToast` (stored in `session`). Otherwise the centered `SessionView`.
- `showCelebration()`: top-right when the celebration habit is water (5d) or uses the corner; otherwise centered. Exhaustive switch in one private helper.
- `showSnoozed(id, until:)`: closes any old note, shows `SnoozedNote(id:until:)` in a `CornerToast` (stored in a new `note` property), and closes it after `Timing.cornerNoteDuration` with a `DispatchWorkItem` (or `Task`) that is cancelled when a new note or a new bubble shows. `showBubble` closes the note first.

### `CelebrateView` dispatch

`.water` → `WaterThanks`; `.reading` → `e.usesCorner(.reading) ? ReadingDoneCard() : LegacyCelebrate()`; `.meditation` → `LegacyCelebrate()`. (No `id == .x` comparisons; use the switch.)

### `ReadingInvite(level:)` (`Features/Reading/ReadingInvite.swift`)

Card: width `UIMetrics.cornerWidth` (330), padding 14, spacing 12, fill `Night.card`, radius 18, border `Night.heroBorder(.reading)` 1 pt (at `.persist`: `Night.reading` 2 pt), shadow black 0.55, radius 22, y 18. Outer padding `bubbleShadowPadding`.

1. Row: `BobbingBuddy(habit: .reading, size: UIMetrics.cornerBuddySize)` (52). Text column:
   - Eyebrow "BOI · READING" (`Typography.eyebrow`, `Night.reading`).
   - Title `e.copy.title` (`Typography.cardTitle` size 16 → add `Typography.cornerTitle`).
   - Hint `Copywriter.readingInviteHint(minutes: sessionMinutes)` (`hint`, `Night.muted`).
   - At `.nudge` only: an X button (SF Symbol `xmark`, accessibility label "Dismiss") at the top right → `e.snooze()`. At `.persist` there is no X (Nudgy rule: no close button).
2. Buttons row: "Start reading" (accent button, `Night.reading` fill, `Night.onAccent` text, fills the width) → `e.startReading()`; `e.snoozeShortLabel` ("In 5 min", ghost) → `e.snooze()`. Height 34.
3. At `.persist`: the card wiggles every `UIMetrics.shakeInterval` (same `.task(id: level)` pattern as `WaterBubble`, `.tink` sound), and shows the hint `e.warnText(.reading)` below the buttons.

### `ReadingTimerPill` (`Features/Reading/ReadingTimerPill.swift`)

Capsule: fill `Night.card`, border `heroBorder(.reading)`, padding (8, 10, 8, 8), shadow.

- Ring 36 pt, line 3.5, track `Night.fieldBorder`, arc `Night.reading`, starts at the top. The arc shows the remaining part: start value `remaining / total`, then `withAnimation(.linear(duration: remaining))` to 0 in `onAppear`. No animation with Reduce Motion (the ring then stays at the start value). `total` = `sessionEnd - sessionStart`, `remaining` = `max(0, sessionEnd - e.now)`.
- Text column: `Text(timerInterval: e.now...e.sessionEnd, countsDown: true)` + " left" (14 pt black, monospaced digits); below it "Boi is reading with you" (`hint`, 11 pt).
- Button "Stop" (ghost capsule, height 30) → `e.stopSession()`.
- No `TimelineView`, no timer. The Engine finishes the session at `sessionEnd` as today.

`Engine.sessionStart` and `sessionEnd` must be readable from SathiUI (`package` getters) if they are not.

### `ReadingDoneCard` (`Features/Reading/ReadingDoneCard.swift`)

Card like `ReadingInvite` but width `UIMetrics.cornerDoneWidth` (300), one row: `StaticBuddy(habit: .reading)` at 44, text column `Copywriter.readingDoneTitle(minutes: Int(e.celebration.amount))` (15 pt black) and `Copywriter.readingDoneHint(streak: e.streak(.reading))` (`hint`), and an X button (accessibility label "Close") → `e.endCelebrate()`. It closes by itself after `Timing.celebrationDuration` (Engine, unchanged).

### `SnoozedNote(id:until:)` (`Features/Reading/SnoozedNote.swift`)

Capsule, fill `Night.card`, border `Night.border`, padding (8, 14): text `e.comesBackText(id, until: until)` (`hint`, `Night.chipText`). No buttons (the canvas "Replay" is a design demo only).

### Constants (`UIMetrics+Corner.swift`)

`cornerWidth` 330, `cornerDoneWidth` 300, `cornerPadding` 14, `cornerSpacing` 12, `cornerRadius` 18, `cornerBuddySize` 52, `cornerDoneBuddySize` 44, `cornerButtonHeight` 34, `pillRingSize` 36, `pillRingLine` 3.5, `pillButtonHeight` 30, `pillPadding` (8, 10, 8, 8), `notePadding` (8, 14), `closeIconSize` 14, `closeButtonSize` 26, `fontCornerTitle` 16, `fontPillTime` 14. `Typography.cornerTitle`, `Typography.pillTime`.

## Notes from the red step

- Stopping the timer pill early does not show the "comes back" note. `stopSession()` calls `snoozeHabit`, not `snooze()`; keep it so.
- Tests find "Start reading", "In 5 min", "Stop" as buttons holding that text, and "Dismiss" and "Close" by accessibility label.
- If ViewInspector cannot walk `Text(timerInterval:countsDown:)`, keep "Boi is reading with you" in a separate child view of the pill so the test can still find it.

## Tests that define done

Core (`SathiCoreTests`):

1. `usesCorner`: reading + `.corner` → true; reading + `.focus` → false; water → false; meditation → false.
2. Reading bubble (corner) → `snooze()` → presenter calls contain `closeBubble` then `showSnoozed(.reading, until: now + 5 min)`.
3. Reading bubble (corner) not answered for `ignoreMinutes` → auto snooze → `showSnoozed` call.
4. Reading bubble with `.focus` → `snooze()` → no `showSnoozed` call. Water bubble → `snooze()` → no `showSnoozed` call.
5. `Copywriter.comesBack(.reading, at: 22:10, calendar: Berlin)` → "Boi comes back at 10:10 PM" (use the same formatter in the expected value if the test machine locale can change the format; at least check the prefix "Boi comes back at " and that it contains "10:10").
6. `readingInviteHint(minutes: 15)` → "15 calm minutes with your book."
7. `readingDoneTitle(minutes: 15)` → "Lovely, 15 minutes read"; `1` → "Lovely, 1 minute read".
8. `readingDoneHint(streak: 6)` → "That is 6 days in a row."; `1` and `0` → "A good start."
9. `snoozeShortLabel` with `snoozeMinutes` 5 → "In 5 min"; 10 → "In 10 min".
10. Corner reading session started and stopped early from a reminder → snoozed, no done event (Schedules rule 6, unchanged; guard test).

UI (`SathiUITests`, ViewInspector):

11. `ReadingInvite(level: .nudge)` shows "BOI · READING", `e.copy.title`, "15 calm minutes with your book.", "Start reading", "In 5 min", and a button with accessibility label "Dismiss".
12. Tap "Start reading" → phase `.session(.reading)`.
13. Tap "In 5 min" → phase `.idle`, `state(.reading).snoozes == 1`.
14. Tap "Dismiss" → phase `.idle`, snoozes 1.
15. `ReadingInvite(level: .persist)` has no "Dismiss" button and shows `e.warnText(.reading)`.
16. `ReadingTimerPill` during a reading session shows "Boi is reading with you" and a "Stop" button; tap "Stop" → phase `.idle`, no new done event.
17. `CelebrateView` after a corner reading session → contains `ReadingDoneCard`, "Lovely, 15 minutes read", and the hint; tap "Close" → phase `.idle`.
18. `CelebrateView` after a `.focus` reading session → contains `LegacyCelebrate` ("15 min read", `ReadingWeekRow`), not `ReadingDoneCard`.
19. `BubbleView(id: .reading, ...)` stays `LegacyBubble` (the focus path still uses it; the corner path uses `ReadingInvite` from `UIController`).
20. `SnoozedNote(id: .reading, until:)` shows `e.comesBackText(.reading, until:)`.

Update the existing tests that the change breaks (for example, old celebration tests that run a reading session with the default `.corner` style and expect the legacy card: set `.focus` in those tests, or move them to test 17).
