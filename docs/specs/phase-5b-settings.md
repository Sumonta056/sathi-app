# Phase 5b: Settings window

Goal: replace the old `Form` settings with the canvas design: an 860×620 dark window with a sidebar and one tab per buddy. Two small Core additions back it: reading weekdays and the reading reminder style. Strictness labels change to Gentle / Nudgy / Strict.

Rules: `.claude/rules/business-logic.md` (Schedules rule 8, Escalation rule 2 and 4). Design: https://claude.ai/artifact/AgF243uMtC5H8ySBfdXx6e (Settings artboard). Shared parts: `docs/specs/phase-5a-theme.md`.

## Part 1: Core

### `Weekday` (`SathiCore/Habits/Reading/Weekday.swift`)

```swift
package enum Weekday: Int, Codable, CaseIterable, Sendable {
    case monday = 2, tuesday = 3, wednesday = 4, thursday = 5, friday = 6, saturday = 7, sunday = 1
    package var shortLabel: String   // "M", "T", "W", "T", "F", "S", "S"
    package var name: String         // "Monday" ... "Sunday"
}
```

- Raw value = `Calendar.component(.weekday)` (1 = Sunday).
- `allCases` order is Monday first (the declaration order above).

### `ReadingReminderStyle` (`SathiCore/Habits/Reading/ReadingReminderStyle.swift`)

```swift
package enum ReadingReminderStyle: String, Codable, CaseIterable, Sendable { case corner, focus }
```

### `ReadingPrefs`

- New `package var weekdays: Set<Weekday> = Set(Weekday.allCases)`.
- New `package var reminderStyle: ReadingReminderStyle = .corner`.
- Decoding: a missing field gets the default (old files keep working). An empty `weekdays` array decodes as empty (rules treat it as every day).
- Encoding: `weekdays` is written as an array sorted Monday first (stable files), like `MeditationPrefs.slots`.
- New `package var sortedWeekdays: [Weekday]`.

### `Prefs.scheduleKey`

Adds the sorted weekdays, so a weekday change reschedules. `reminderStyle` is not in the key.

### `ReadingRules`

- `nextDue(now:lastDone:doneToday:skipToday:)`: start day = today, or tomorrow when `skipToday` or the goal is met. Step forward day by day (at most 7 steps) to the first selected weekday. Return the set time on that day. If the start day is today and today is selected, the result is today's set time, even when it is in the past (missed slot at launch is due now, rule 5).
- `nextSlot(after:)`: the first set time strictly after `date` on a selected weekday.
- Empty `weekdays` acts as all 7 days.
- Day steps use `clock.calendar` (DST-safe `date(byAdding: .day)`); the weekday comes from `clock.calendar.component(.weekday, from:)`.

### `Strictness` labels (raw values unchanged)

| Case | `title` | `detail` |
|---|---|---|
| `friendly` | Gentle | A bubble each time. It never stays on top. |
| `persistent` | Nudgy | Stays on top and wiggles after a snooze. |
| `strict` | Strict | Locks the screen after two snoozes. |

Add `package var level: Int` (1, 2, 3) for the dots on the option cards.

## Part 2: UI

All views `internal`. Copy is exact (tests look for it). The window shows `Night` colors only; it never uses the old `Palette`.

### Window (`Windows/UIController.swift`)

- `UIMetrics.settingsSize` becomes 860 × 620.
- Dark title bar: `appearance = NSAppearance(named: .darkAqua)`, `titlebarAppearsTransparent = true`, background `Night.sidebar`. Title stays "Sathi Settings".
- When the window closes, `UIController` drops its reference (delegate `windowWillClose` sets `settings = nil`). The next `showSettings()` makes a new window. Performance rule: closed windows hold no views.
- Root view gets `.environment(\.colorScheme, .dark)`.

### Navigation (`Features/Settings/`)

```swift
enum SettingsTab: Hashable { case general, habit(HabitID), addBuddy }
```

- `SettingsView`: `HStack(spacing: 0)` of `SettingsSidebar` (width `UIMetrics.sidebarWidth` = 230, fill `Night.sidebar`) and a `ScrollView` with the selected tab (padding 24 × 28, fill `Night.bg`). `@State var tab: SettingsTab = .general`.
- `SettingsSidebar`:
  - Logo row: sprout leaf in a circle, "Sathi", "Your little helpers".
  - Nav button "General".
  - Faint label "BUDDIES" (`Night.faint` on sidebar).
  - One row per `HabitID.allCases`: nav button (icon in the habit accent, title "Water" / "Reading" / "Meditation") plus a `BuddySwitch` bound to that habit's `enabled`, label "Water reminders" / "Reading reminders" / "Meditation reminders". Meditation shows a "NEW" badge (`Night.calm` fill, `Night.onAccent` text).
  - Nav button "Add a buddy" (sprout text).
  - Bottom: "Open reports" row, disabled, with a "Soon" tag (Reports window comes in 5g).
  - The selected nav button has fill `Night.navSelected` and the trait `.isSelected`.
- Every `switch` on `HabitID` and `SettingsTab` is exhaustive, no `default:`.

### Habit tabs (one file per module, per business rule 1)

Each tab: `HeroCard` at the top (buddy drawing = a static `BuddyCanvas` at time 0, 72 pt, no `TimelineView`), then the sections. When the habit is off, every section under the hero has opacity `UIMetrics.disabledOpacity` (0.35) and is `.disabled(true)`. Each tab ends with a ghost button "Show a reminder now" that calls `e.trigger(id)` (disabled when the habit is off).

**`Features/Water/WaterSettingsTab.swift`**
- Hero: eyebrow "FOTA · WATER", title "Small sips, all day long", hint "Fota taps you on the shoulder when it is time for a glass.", switch label "Water reminders".
- `SectionLabel("Rhythm")`, `SettingsCard`:
  - "Remind me every": `ChipRow` of `Limits.waterIntervalChips` = [30, 60, 90, 120], labels "30 min" … "120 min". Tap sets `intervalMinutes`. A saved value not in the list shows no chip selected.
  - "Between", hint "Fota sleeps outside these hours.": two `TimeMenu`s (start, end) with "to" between.
  - "I drink from": `ChipRow` Glass / Sip bottle → `container`.
  - Only when container is bottle: "My bottle holds", `MiniStepper` over `bottleSizeGlasses` (`Limits.bottleSizeGlasses`, step `Limits.bottleSizeStep`), text "3 glasses".
- `SectionLabel("Daily goal")`: `GlassGoalRow`: one glass shape per glass up to `Limits.dailyGoalGlasses.upperBound`, the first `goal` filled with `Night.water`; buttons "Fewer glasses" (−) and "More glasses" (+) (accessibility labels) inside the range; big number and "glasses".
- `SectionLabel("If I ignore Fota")`: three `OptionCard`s for `Strictness.allCases` (title, detail, dots = `level`), accent water.

**`Features/Reading/ReadingSettingsTab.swift`**
- Hero: "BOI · READING", "A few pages before bed", "Boi peeks in from the corner. It never blocks your screen.", switch label "Reading reminders".
- `SectionLabel("When")`, `SettingsCard`:
  - "Remind me at": `TimeMenu` → `timeMinutes`.
  - "On these days": `ChipRow` of `Weekday.allCases`, label `shortLabel`, multi-select on `weekdays`. Each chip has accessibility label `name`. A tap on the only selected day does nothing.
  - "Session length": `ChipRow` of `Limits.sessionLengths` → `sessionMinutes`.
- `SectionLabel("How Boi says hi")`: two `OptionCard`s: "Corner popup" / "A small card in the top-right. Keep working while it waits." and "Focus screen" / "Dims the screen and starts the timer. For deep reading nights." → `reminderStyle`.
- `SectionLabel("If I ignore Boi")`: `OptionCard`s for `.friendly`, `.persistent` only. Selected = `prefs.strictness(.reading)` (a stored `.strict` shows Nudgy selected).

**`Features/Meditation/MeditationSettingsTab.swift`** (replaces `MeditationSettingsSection`)
- Hero: "SHANTI · MEDITATION", "Pause. Breathe. Come back.", "Shanti guides a short breath with a soft glowing circle.", switch label "Meditation reminders".
- `SectionLabel("When")`, `SettingsCard`:
  - "Remind me in the", hint "Pick one or more.": `ChipRow` of `MeditationSlot.allCases` (labels "Morning", "Afternoon", "Evening"), multi-select on `slots`. A tap on the only selected slot does nothing.
  - "Session length": `ChipRow` of `Limits.meditationLengths` → `sessionMinutes`.
  - "Soft chime at the end": `BuddySwitch` (label "Chime") → `chime`.
- `SectionLabel("Breathing pattern")`: three `OptionCard`s, top text = beats joined by "·" from `BreathingPattern.steps(style)` (for example "4·4·4·4"), titles "Box" / "Wind down" / "Even", details "Steady and calm." / "Good before sleep." / "Simple in and out." → `style`.

### `Features/Settings/GeneralTab.swift`

- Title "Hi there", subtitle "A few things that apply to every buddy."
- `SectionLabel("You")`: row "What should we call you?" with a `TextField` → `general.name`.
- `SectionLabel("Look and feel")`: three theme `OptionCard`s: "Night sprout" (selected, enabled), "Morning dew" and "Follow macOS" (disabled, detail "Soon").
- `SectionLabel("Reminders")`: rows "Snooze for" (`MiniStepper` over `snoozeMinutes`, `Limits.snoozeMinutes`, "5 min") and "Count it as a snooze after" (`ignoreMinutes`, `Limits.ignoreMinutes`, "5 min").
- `SectionLabel("Behaviour")`: rows with `BuddySwitch` (accent sprout):
  - "Open Sathi when I log in" (label "Open at login"): `SMAppService.mainApp`; on failure it shows the real status.
  - "Play soft sounds", hint "A tiny pop when a buddy says hi." (label "Sounds") → `soundOn`.
  - "Stay quiet in meetings", hint "Soon: buddies wait while the camera, mic, or a full-screen app is on." (label "Quiet in meetings"): off and disabled.

### `Features/Settings/AddBuddyTab.swift`

Title "Add a buddy", subtitle "Each buddy is its own module. Turn one on and it gets its own tab." A 2-column grid of four cards: Stretch "Loosen up every hour.", Eye break "20 seconds, 20 feet away.", Walk "A short walk after lunch.", Posture "Sit tall, shoulders down." Each card: initial badge, title, detail, disabled button "Soon".

### Small shared parts (`Features/Settings/`)

- `TimeMenu(minutes: Binding<Int>)`: a `Menu` over `TimeSlots.all`, label = the slot label (for example "9:30 AM"), styled as a dark time button.
- `MiniStepper(value:range:step:format:)` with "−" / "+" buttons (accessibility labels "Less" / "More"), clamped to the range.
- `GlassGoalRow(goal: Binding<Double>)`.

### Constants

`UIMetrics`: `settingsSize` 860×620, `sidebarWidth` 230, `contentPadding` 24×28, `disabledOpacity` 0.35, `heroBuddySize` 72, `navIconSize` 22, `glassIconSize` 22×28. `Limits.waterIntervalChips = [30, 60, 90, 120]`.

### Delete

`SettingsSections.swift`, `MeditationSettingsSection.swift`, the old `StrictnessPicker` and `TimeSlotPicker` (replaced by `OptionCard` and `TimeMenu`). Old tests that check the old `Form` (`SettingsViewTests`, `MeditationSettingsFixTests`) are rewritten for the new views with the same behaviors.

## Tests that define done

Core (`Tests/SathiCoreTests/`):

1. `ReadingPrefs` defaults: all 7 weekdays, `reminderStyle == .corner`.
2. Decoding an old reading prefs JSON without `weekdays` / `reminderStyle` gives the defaults; other fields keep their values.
3. Encoding writes `weekdays` sorted Monday first; a round trip keeps the set.
4. `scheduleKey` changes when a weekday is turned off and does not change when `reminderStyle` changes.
5. `ReadingRules.nextDue` with Saturday and Sunday off, now = Friday 23:00 after the set time, goal met → Monday at the set time.
6. `nextDue` on a day that is off (now = Saturday 08:00, Sat/Sun off, nothing done) → Monday at the set time.
7. `nextDue` on a selected day before the set time → today at the set time; after the set time with nothing done → today's set time (in the past).
8. `nextSlot(after:)` skips days that are off.
9. Empty `weekdays` behaves as every day.
10. Engine: turning today's weekday off in prefs reschedules reading to the next selected day.
11. `Strictness` titles Gentle / Nudgy / Strict, levels 1 / 2 / 3, raw values unchanged.

UI (`Tests/SathiUITests/`, ViewInspector, `EngineHarness`):

12. Sidebar shows "General", "Water", "Reading", "Meditation", "Add a buddy", "Open reports"; the Meditation row shows "NEW".
13. The sidebar `BuddySwitch` "Reading reminders" turns `prefs.reading.enabled` off.
14. A nav tap on "Water" shows the water tab ("Small sips, all day long"); "Add a buddy" shows "Stretch" and four "Soon" buttons.
15. Water: chip "60 min" sets `intervalMinutes` to 60; a saved 45 shows no selected interval chip.
16. Water: "More glasses" raises the goal by 1; it never goes over `Limits.dailyGoalGlasses.upperBound`; "Fewer glasses" never below the lower bound.
17. Water: the "Strict" option card sets `strictness` to `.strict`; the "My bottle holds" row shows only for the bottle container.
18. Reading: chip "Saturday" (accessibility label) turns Saturday off; a tap on the only selected day keeps it on.
19. Reading: "Focus screen" sets `reminderStyle` to `.focus`.
20. Reading: ignore cards show only "Gentle" and "Nudgy"; a stored `.strict` shows "Nudgy" selected.
21. Meditation: slot chip tap toggles; the last slot cannot be removed; "Wind down" sets style `.relax`; the "Chime" switch flips `chime`; beats text "4·4·4·4" is shown.
22. A habit that is off: its "Show a reminder now" button is disabled; when on, a tap triggers that habit (phase becomes `.bubble(id, …)`).
23. General: the name field edits `general.name`; "Snooze for" "More" raises `snoozeMinutes` by 1 and stops at the upper bound; "Quiet in meetings" switch is disabled; "Morning dew" card is disabled.

All old Core tests pass. No file over 200 lines. No comments. `/perf-check` is run once in 5h; this slice adds no animation loop.
