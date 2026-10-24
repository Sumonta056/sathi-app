# Phase 5a–5c review fixes

Source: the shared code review of slices 5a–5c. Rules: `.claude/rules/business-logic.md` (Habits 7–8, Schedules 8–9, Escalation table).

## Fixes and the tests that define done

### F1. A settings change cancels a reminder that moved into the future (Habits rule 8)

`Engine.reschedule()`: when the fresh due time of an enabled habit is after `clock.now`, remove the habit from `queue` and set its `snoozedUntil` to nil. Do not touch the habit that is showing now (`phase` bubble/session of that habit) unless the habit was turned off.

Tests (Core):
1. Wed 22:00, water bubble showing, reading queued. Turn Wednesday off → reading leaves the queue; `nextDue` = Thu 22:00; after water is done, no reading bubble shows on Wednesday.
2. Reading snoozed until 22:10 on Wednesday. Turn Wednesday off → `snoozedUntil == nil`, no reading bubble at 22:10, `nextDue` = Thu 22:00.
3. Meditation evening slot queued; remove the evening slot → meditation leaves the queue.
4. A change that does not move the due time into the future (for example water interval change while water is queued and still due) keeps the habit in the queue.

### F2. "Rest of day" skips missed slots (Habits rule 7)

`Engine.pauseRestOfDay()`: set `pausedUntil` to the next midnight, clear `queue`, clear every habit's `snoozedUntil`, and set each enabled habit's due time to `rules(id).nextSlot(after: pausedUntil - 1 s)` (fall back to `nextDue` from that time when `nextSlot` is nil). Then request a tick.

Tests (Core):
5. 2026-03-04 20:00, reading on (22:00), meditation evening on: tap rest of day; at 00:00 and at 09:00 next day no reading or meditation bubble shows; reading's due is 2026-03-05 22:00.
6. Water due at 16:30, rest of day at 15:00 → at 2026-03-05 water shows at its next active start, not at 00:00.
7. The 30 min pause still keeps a missed reminder: water due during a 30 min pause shows when the pause ends.

### F3. Lenient decoding of sets and enums (Schedules rule 9)

- `ReadingPrefs.weekdays`: decode `[Int]`, `compactMap(Weekday.init(rawValue:))`; an empty result (or empty array) becomes all 7 days.
- `ReadingPrefs.reminderStyle`: an unknown string becomes `.corner`.
- `MeditationPrefs.slots`: decode `[String]`, `compactMap(MeditationSlot.init(rawValue:))`; a non-empty array whose values are all unknown becomes the default slots; a literal `[]` stays empty (existing behavior: meditation may have no slots).
- `MeditationPrefs.style`: unknown → `.box`.

Tests (Core, JSON fixtures):
8. `"weekdays":[2,9]` → `[.monday]`; other prefs (name, water) keep their values.
9. `"weekdays":[]` → all 7 days.
10. `"reminderStyle":"silent"` → `.corner`; name keeps its value.
11. `"slots":["morning","night"]` → `[.morning]`; `"style":"square"` → `.box`.

### F4. Strictness copy

| Case | `detail` |
|---|---|
| `friendly` | A reminder each time. It never stays on top. |
| `persistent` | Stays on top, wiggles, and has no close button after a snooze. |
| `strict` | Locks the screen after two snoozes. |

Test 12: update `StrictnessLabelTests` details to this table.

### F5. Test quality

13. Autumn DST: Berlin, only Monday selected, now = Sat 2026-10-24 23:00, goal met → Mon 2026-10-26 22:00 local.
14. `EngineMenuTests`: the meditation goal text is the literal "of 10 min" (default 2 slots × 5 min).
15. `SettingsViewTests` helper: replace `id == .water ? on : true` with an exhaustive `switch`.
16. `Tests/SathiCoreTests/SetKeepOneTests.swift`: add, remove, keeps the last one.
17. Settings window: `SettingsWindow.make` returns a window with `isReleasedWhenClosed == false` and the given delegate; calling the delegate's `windowWillClose` runs `onClose`.

### F6. Small UI fixes (no new behavior test unless noted)

- `HabitCard`: compute `e.progress(id)` once per body.
- `MenuHeader`: greeting and date use the same time (`e.now`). `Engine.greeting` reads `now`; update the Core test that moves `clock.now` without a tick if it conflicts, as a separate explained change.
- `SettingsView`: `@State private var tab`, with `init(tab: SettingsTab = .general)`.
- `NapBanner`: when `pausedUntil` is the start of a day after today, text "Buddies are napping until tomorrow". Test 18.
- `BuddySwitch`: `.accessibilityRepresentation { Toggle(label, isOn: $isOn) }` if the existing `BuddySwitch` tests still pass; otherwise leave as is and report.
- Settings window title bar: root `.ignoresSafeArea()`, sidebar top padding `UIMetrics.titleBarInset` (28) so the logo sits below the traffic lights. Visual check later.
- Delete `Engine.subtitle(_:)` if only tests use it, with its tests moved to `goalText`.
