# Phase 3: Meditation (Shanti), core

Goal: add a third habit, Meditation, with the buddy Shanti. It uses time slots, a timed breathing session, and never locks the screen. The UI gets only the minimum to compile and to be usable; Phase 5 redesigns it.

Rules: `.claude/rules/business-logic.md`. Design: https://claude.ai/artifact/AgF243uMtC5H8ySBfdXx6e (Meditation tab, MeditateBubble).

## Habit

- `HabitID.meditation`: `name` "Meditation", `buddy` "Shanti". Raw value `"meditation"`.
- Every exhaustive `switch` on `HabitID` gets a `.meditation` case. No `default:`.

## Prefs (`SathiCore/Habits/Meditation/`)

```swift
package enum MeditationSlot: String, Codable, CaseIterable, Sendable { case morning, afternoon, evening }
package enum BreathingStyle: String, Codable, CaseIterable, Sendable { case box, relax, even }

package struct MeditationPrefs: Codable, Equatable, Sendable {
    package var enabled = false
    package var slots: Set<MeditationSlot> = [.morning, .evening]
    package var sessionMinutes = 5
    package var style: BreathingStyle = .box
    package var chime = true
    package var strictness: Strictness = .friendly
}
```

- `enabled` defaults to `false`, so an update never starts a new reminder that the user did not ask for. The Settings shows it with a "New" label.
- Missing keys decode to defaults (same pattern as `ReadingPrefs`).
- `Prefs.meditation = MeditationPrefs()`; `Prefs` decodes a missing `meditation` key to defaults.
- `Prefs.scheduleKey` includes `meditation.enabled`, the sorted slots, and `meditation.sessionMinutes`.
- Slot times in `Limits`: `meditationSlotMinutes: [MeditationSlot: Int] = [.morning: 8 * 60, .afternoon: 14 * 60, .evening: 21 * 60 + 30]`. `meditationLengths = [2, 5, 10]`.

## Escalation rule (business rule: only Water may use Strict)

- `Prefs.strictness(_ id:)` returns `.persistent` when the stored value is `.strict` for `.reading` or `.meditation`. Water is unchanged.
- This is a behavior change for Reading: a stored `.strict` no longer locks. Test it.

## Rules (`MeditationRules`)

- `id = .meditation`.
- `dailyGoal = Double(sessionMinutes * slots.count)`.
- `isActiveTime` is always `true`. `nextActiveStart(after:)` returns its input.
- `total(on:data:)` = sum of `.done` meditation minutes that day (`Stats.total`).
- `nextDue(now:lastDone:doneToday:skipToday:)`:
  1. No slots selected: `.distantFuture`.
  2. `skipToday`: the first selected slot of tomorrow.
  3. `base` = `lastDone` when `lastDone` is on the same day as `now`, else one second before the start of `now`'s day.
  4. Result: the first selected slot time that is later than `base`, searching today, then tomorrow.
  - Example (slots morning 8:00 and evening 21:30): launch at 15:00 with no session today → 8:00 today (overdue, so due now). Done at 15:05 → 21:30 today. Done at 21:40 → 8:00 tomorrow.
- `Persisted.lastDone(.meditation)` = date of the last `.done` meditation event in `events`, else `nil`.

## Breathing pattern (`SathiCore/Habits/Meditation/BreathingPattern.swift`)

```swift
package enum BreathPhase: String, Sendable { case inhale, hold, exhale, rest }
package struct BreathStep: Equatable, Sendable { package var phase: BreathPhase; package var remaining: TimeInterval; package var cycle: Int }
package enum BreathingPattern {
    package static func steps(_ style: BreathingStyle) -> [(BreathPhase, TimeInterval)]
    package static func cycleLength(_ style: BreathingStyle) -> TimeInterval
    package static func step(_ style: BreathingStyle, at elapsed: TimeInterval) -> BreathStep
}
```

| Style | Steps (seconds) | Cycle |
|---|---|---|
| box | inhale 4, hold 4, exhale 4, rest 4 | 16 |
| relax | inhale 4, hold 7, exhale 8 | 19 |
| even | inhale 5, exhale 5 | 10 |

- `step(at:)`: `cycle` starts at 0. `remaining` = seconds left in the current phase. A negative `elapsed` acts as 0. A phase boundary belongs to the next phase (box at 4.0 → hold, remaining 4).
- Durations live in `Timing` (`breathBox`, `breathRelax`, `breathEven` or one table). No magic numbers.

## Sessions

- `Phase.session` becomes `Phase.session(HabitID)`.
- `Engine.startSession(_ id: HabitID)` replaces the body of `startReading()`. Keep `startReading()` and add `startMeditation()` as one-line wrappers. Allowed only for `.reading` and `.meditation`; `.water` beeps and does nothing.
- Session length: reading `reading.sessionMinutes`, meditation `meditation.sessionMinutes`.
- `finishSession()` records `.done(id, minutes)` for the session's habit, sets the next due time, and celebrates that habit.
- `stopSession()` records `.snooze(id)` and snoozes that habit.
- `isActive(id)` and `focus` use the habit inside `.session(h)`. `TickPlanner` keeps `Timing.activeTick` for any `.session(_)`.
- `lockConfirmed(.meditation)` calls `startMeditation()` (never reached, but exhaustive).
- Display: pill "Breathing…" for a meditation session, "Reading…" for reading. Status call to action "Breathe!". Mood during a meditation session: `.reading` for now (a new mood comes with the Phase 5 art). Subtitle: "`done` of `goal` min · `n`-day streak". Greeting sound `.tink`.
- Copywriter: 2 nudge and 2 persist lines for Shanti, and 3 celebration titles, in the same friendly tone.

## Minimum UI (SathiUI) to compile and be usable

- `BuddyKind.pebble` for meditation. `BuddyCanvas` draws a simple lavender round body with closed eyes and a small green leaf (Phase 5 polishes it). `Palette.calm = #A99CF5`, `Palette.calmDeep = #4B3F9E`.
- `HabitRow` button "Breathe" → `startMeditation()`. `BubbleView` meditation shows a "Start N-min breathing" button. `CelebrateView` meditation badge "N min calm" and subtitle with the streak.
- `SessionView` shows the session habit's buddy, title ("READING · DO NOT DISTURB" or "BREATHING"), and the clock. For meditation it also shows the current `BreathingPattern` phase text ("Breathe in", "Hold", "Breathe out", "Rest") from the same refresh it already has. No new timer.
- `SettingsView`: a "Meditation · Shanti" section: enable toggle, slot toggles, length picker (`Limits.meditationLengths`), style picker, chime toggle, and a "Show meditation reminder now" button.

## Tests that define done

1. `MeditationRulesTests`: every example above; no slots → `.distantFuture`; `skipToday`; `lastDone` yesterday is ignored; `dailyGoal` follows slots and length; `total` counts only done meditation minutes.
2. `BreathingPatternTests` (parameterized): each style's cycle length; phase and remaining at 0, mid-phase, every boundary, and in the second cycle; negative elapsed.
3. `ModelTests`/`PrefsCodingTests`: meditation defaults; `{}` and a `Prefs` JSON without `meditation` decode to defaults; `scheduleKey` changes when slots change; `strictness(.reading)` and `strictness(.meditation)` return `.persistent` for a stored `.strict`, water keeps `.strict`.
4. `EngineMeditationTests`: enabled meditation becomes due at its slot and shows a bubble; `startMeditation` → `.session(.meditation)` → after the length, one `.done(.meditation, 5)` event and a celebration; stop early records a snooze; water due during a meditation session waits in the queue; strict stored for meditation never locks after 2 snoozes; meditation disabled by default never becomes due.
5. Existing tests: `.session` → `.session(.reading)`; all still pass.
6. UI: `HabitRow` for meditation shows "Breathe" and taps `startMeditation`; the Settings meditation section exists.

## Decisions made while writing the tests

1. `MeditationRules(prefs:calendar:)` mirrors `ReadingRules`. `MeditationPrefs` has `package init()`.
2. A slot equal to `lastDone` does not count ("later than `base`"): done at 8:00 → next due 21:30.
3. Scheduling ignores `doneToday`.
4. `scheduleKey` ignores `style` and `chime`.
5. UI labels tested: section header "Meditation · Shanti", a "New" label, button "Show meditation reminder now", bubble button "Start N-min breathing", row button "Breathe", celebration badge "N min calm", session title "BREATHING", phase texts "Breathe in" / "Hold" / "Breathe out" / "Rest".

## Review fixes (round 1)

User decisions (2026-10-24): a stop with nothing due does nothing; a settings change never fires a past slot.

### F1. Stop early only snoozes a due reminder
- `startSession(id)` remembers whether the session came from a due reminder: `fromReminder = isDue(id) || now >= (snoozedUntil ?? nextDue)` at start.
- `stopSession()`: when `fromReminder`, record `.snooze(id)` and snooze (as now). Otherwise go back to idle, record nothing, and keep `nextDue` and `snoozes` unchanged.
- Applies to Reading and Meditation.

### F2. A settings change never fires a past slot
- `HabitRules` gets `func nextSlot(after date: Date) -> Date?`: the next clock time strictly after `date` for clock-scheduled habits (Reading: today's or tomorrow's reading time; Meditation: the next selected slot, nil when no slots). Water returns `nil`.
- `Engine.reschedule()` (runs on a schedule pref change): when the new due time is earlier than `now` and `nextSlot(after: now)` is not nil, use that slot. Launch and wake keep the old rule (a missed slot is due now).
- When a habit's due time becomes `.distantFuture` (no slots), `reschedule()` also clears its `snoozedUntil` and removes it from the queue.

### F3. Clock times are wall-clock times (DST)
- `DayClock.at(_:on:)` uses `calendar.date(bySettingHour:minute:second:of:)`. On a DST day, 8:00 is 8:00 local time.

### F4. A goal of 0 never counts as met
- `Stats.streak` counts a day only when `goal > 0`. Meditation with no slots has streak 0.

### F5. Chime at the end
- A meditation session start plays no sound. At the end, Meditation plays `.tink` instead of `.hero` when `chime` is on, and no sound when it is off. Reading and Water keep `.hero`.
- The Settings toggle reads "Soft chime at the end".

### F6. Strict is only for Water in the UI
- The Reading strictness picker offers Friendly and Persistent only. Its selection shows `prefs.strictness(.reading)`, so a stored Strict shows as Persistent.

### F7. Smaller fixes
- `MeditationSlot.minutes`: an exhaustive `switch` that reads named `Limits` constants (`morningSlotMinutes`, `afternoonSlotMinutes`, `eveningSlotMinutes`). No dictionary with `?? 0`.
- `finishSession` records the real length: `Int(((sessionEnd - sessionStart) / Timing.minute).rounded())`.
- `Persisted.lastDone(.meditation)` uses the latest date (`max`), not the last array item.
- `MeditationPrefs` encodes `slots` as a sorted array (stable file output); it still decodes any order.
- `SessionView` shows the habit of the running session; when there is no session it shows nothing.
- "Show meditation reminder now" is disabled while Meditation is off.

### Tests that define done (round 1)
1. F1: stop a menu-started session at 15:00 (next slot 21:30): phase idle, no event, `snoozes == 0`, no bubble at 15:10, next due still 21:30. Stop a session started from a due bubble: one snooze event (unchanged). Same for Reading.
2. F2: enable Meditation at 23:00 (slots morning, evening; nothing done): no bubble; next due 8:00 tomorrow. Done at 8:05, add Afternoon at 16:00: next due 21:30, no bubble. Remove all slots while Meditation is snoozed: no bubble later, not in the queue. Launch at 15:00 with a missed 8:00 slot: bubble now (unchanged).
3. F3: calendar in `America/New_York`: `at(480, on: 2026-03-08)` is 08:00 local and `at(480, on: 2026-11-01)` is 08:00 local; Meditation and Reading due times on those days are at the wall-clock time.
4. F4: Meditation enabled with no slots: `streak(.meditation) == 0`.
5. F5: meditation finish with chime on plays `.tink` and not `.hero`; with chime off plays neither; start plays no sound. Reading finish still plays `.hero`.
6. F6: the Reading picker has no "Strict" option; a stored `.strict` shows "Persistent" selected.
7. F7: change the length from 10 to 2 during a 10-minute session: the done event has 10 minutes. `lastDone` with out-of-order events returns the latest. Encoded slots are sorted (`["evening","morning"]` order by raw value or by slot order — use `MeditationSlot.allCases` order: morning, afternoon, evening). The reminder button is disabled when Meditation is off.
