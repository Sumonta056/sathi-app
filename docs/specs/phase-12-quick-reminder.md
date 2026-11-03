# Phase 12: Quick reminder

The user writes a one-off reminder ("Call mom") for a particular time. At that time a calm corner popup shows it, and it comes back until the user taps Done.

Design: https://claude.ai/artifact/Cj6jHTShgvTFXxyZ6ZFPjs (artboards 1 to 5).

## Rules

1. A quick reminder is a note, not a habit. It has no streak, no goal, no history event, no stats, and no row in the day summary. It is not a `HabitID`.
2. Text: the app trims spaces and changes each line break to a space. Empty text is refused (`.empty`). The maximum is `Limits.quickTextMax` (80) characters. The form stops input at 80, and the decoder cuts longer saved text to 80.
3. Count: at most `Limits.quickMax` (20) pending reminders. An add at 20 is refused (`.full`).
4. When:
   - `.inMinutes(n)`: `now + n` minutes, to the whole second. The chips are `Limits.quickChips` = 5, 15, 30, 60. The labels are "5 min", "15 min", "30 min", and "1 hour".
   - `.at(minutes:)`: any minute of the day (`0 ..< Limits.minutesPerDay`), as wall-clock time (`DayClock`). A time at or before `now` goes to the same minute tomorrow.
5. Due: a reminder shows when `now >= fireDate`, where `fireDate = snoozedUntil ?? due`. Pauses (30 min, 1 hour, rest of day), weekdays, and days off do not stop it. A time that passes while the Mac sleeps or the app is closed shows at the next tick. Each reminder is independent. Reminders that are due at the same time each show their own popup, in order of `fireDate`, then `createdAt`. They stack in the corner like the buddies (Habits rule 6).
6. Popup: the corner panel (`CornerToast`). It never takes focus. Content: bell icon, eyebrow "QUICK REMINDER · {due time}", the text, "You set this at {created time}.", a "Done" button, a snooze button "In {snoozeMinutes} min", and a close button. Accent color `Night.quick` = `#FF9FB8`.
7. Sound: 1 `.ping` each time a popup shows, at every level. A lock plays `.sosumi`. With sound off, nothing plays (the existing `play` rule).
8. Level: `Prefs.quick.strictness` (default `.persistent`, Nudgy) applies to all quick reminders. `EscalationPolicy.presentation(for:snoozes:)` with the reminder's own `snoozes` picks the form:
   - Gentle: popup at `.nudge` each time.
   - Nudgy: `.persist` after 1 snooze. The popup wiggles and has no close button.
   - Strict: a full-screen lock after 2 snoozes. The lock has "Hold for Done" (it calls Done) and a small "Delete this reminder" link (it calls Delete).
   - Only 1 lock shows at a time, for buddies and quick reminders together. When a lock already shows, a quick reminder that reaches its lock shows a `.persist` popup instead. When it has no snooze left, it becomes the lock as soon as the other lock ends. A buddy waits for a quick lock in the same way.
9. Snooze: the snooze button, the close button, and no answer for `ignoreMinutes` all snooze. A snooze adds 1 to `snoozes`, sets `snoozedUntil = now + snoozeMinutes`, closes the popup, and shows the note "“{text}” comes back at {time}" for `Timing.cornerNoteDuration`. The note cuts text longer than `Limits.quickNoteTextMax` (24) characters and adds "…".
10. Close button: it shows when `Prefs.quick.showsCloseButton` (default `true`) is on, the level is `.nudge`, and a snooze is left.
11. Snooze limit: `GeneralPrefs.snoozeLimit` counts the `snoozes` of each reminder. At the limit the popup has no snooze button, no close button, and no ignore timer. It shows "No snoozes left. It stays until you tap Done." under the text. This is the same as Escalation rule 9.
12. Done removes the reminder and closes its popup or lock. There is no thank-you popup and no event. Delete in the menu does the same.
13. Storage: `LiveState.quickReminders: [QuickReminder]` in `state.json`. An old file without the key loads `[]`. An item that cannot be read is dropped, and the other items stay. An item with empty text is dropped. Text is cut to 80. When there are more than 20 items, the 20 items with the earliest `fireDate` stay. Dates are whole seconds. The open popup or lock is not saved. After a restart, a due reminder shows again at the level that its saved `snoozes` gives.
14. Settings: `Prefs.quick: QuickPrefs` with `strictness` and `showsCloseButton`. A missing key loads the default, and an unknown strictness loads `.persistent`. In Settings, the General tab has a "Quick reminders" card with the 3 level cards and the close-button switch. A change takes effect at the next show.
15. Menu: a "Quick reminders" card sits below the buddy cards and above "Take a break".
    - The header is "Quick reminders" and a badge "{n} of 20" when n > 0.
    - The rows are in `fireDate` order. Each row has a time pill (the `fireDate` time), the text on 1 line, a second line, and a delete button.
    - The second line is "Showing now" while the popup or lock shows, "in {Fmt.short(left)}" when the `fireDate` is today, and "Tomorrow" when the `fireDate` is on a later day.
    - With more than `UIMetrics.quickVisibleRows` (4) rows, the rows scroll inside the card.
    - With no reminders, the card has only the "+ Quick reminder" row.
    - When n > 0, the line "Quick reminders still show during a break." shows under the pause chips.
16. Add form (inline, in the card). The form title is "New quick reminder". A section label "When" sits above the chips. A hint "A time that has passed today goes to tomorrow." sits under the preview.
    - A "Remind me to" text field (`LazyTextField`) and a counter "{n} / 80".
    - The 4 chips. The 15 min chip is selected when the form opens.
    - An "or at" time field (hour and minute). A pick of a time clears the chip selection, and a tap on a chip replaces the time.
    - A preview "Today at {time}" or "Tomorrow at {time}".
    - "Cancel" and "Add reminder". "Add reminder" is disabled when the text is blank. Return in the text field adds.
    - At 20 reminders the form shows "You have 20 quick reminders. Delete one to add more." and has no Add button.
17. The menu bar countdown and status icon do not change.
18. Performance: no new timer. `upcomingDeadlines()` adds each pending `fireDate` and each popup ignore deadline.

## Data shape

```swift
package struct QuickReminder: Codable, Equatable, Identifiable, Sendable {
    package var id: UUID
    package var text: String
    package var due: Date
    package var createdAt: Date
    package var snoozedUntil: Date?
    package var snoozes: Int
    package var fireDate: Date { snoozedUntil ?? due }
}
package struct QuickPrefs: Codable, Equatable, Sendable {
    package var strictness: Strictness = .persistent
    package var showsCloseButton = true
}
package enum QuickTime: Equatable, Sendable { case inMinutes(Int), at(minutes: Int) }
package enum QuickAddResult: Equatable, Sendable { case added(UUID), empty, full }
package enum QuickActivity: Equatable, Sendable { case popup(Level, ignoreDeadline: Date), lock }
```

## Ports

`ReminderPresenter` gets `showQuick(_ id: UUID, _ level: Level)`, `closeQuick(_ id: UUID)`, `showQuickLock(_ id: UUID)`, and `showQuickSnoozed(text: String, until: Date)`. A quick lock closes with the existing `closeLock()`.
