# Changelog

All user-visible changes to Sathi. Each version has a tag `vX.Y.Z` and a GitHub Release with the DMG.

## [Unreleased]

## [3.0.0] - 2026-11-04

Sathi 3.0 adds a fourth buddy, time blocks that write to your calendar, quick reminders, and a new menu.

### Added

- **Shokti** (gym, off by default): suggests 1 short workout every hour during your work hours, on the days you pick, from a list of 4 workouts.
- **Time blocks**: start a focus block from the menu with a planned length or open time. When it ends, Sathi saves an event to the macOS Calendar calendar you pick. An optional floating pill shows a live timer. You can drag it, and for the first 4 seconds it shows Undo. A popup at the end offers Done or +15 min, and an open block checks in every 2 hours.
- **Quick reminders**: write a one-off note for a set time, picked on a 5-minute time grid. A calm corner popup shows it until you tap Done.
- **Day summary**: every evening (10 PM by default) a calm corner popup shows the day for all 4 buddies, and congratulates you when every goal is met.
- **Reading list**: keep a list of things to read. Boi shows the next pick in the popup, the pill, and the menu.
- **Days off**: pick weekdays and single days off for each buddy. A day off keeps that buddy quiet and never breaks its streak.
- Each buddy has its own level (Gentle, Nudgy, Strict) and its own close-button switch. Any buddy at Strict can lock the screen.
- A snooze limit for every buddy, and one list of reminder intervals for all buddies.
- Meditation has a daily goal (5, 10, or 20 minutes), short sessions (1, 2, or 5 minutes), a reminder interval, and active hours. Shanti stops for the day when you reach the goal. The morning, afternoon, and evening slots are gone; your old goal stays.
- Meditation can use Strict: after 2 snoozes, a full-screen lock starts a breathing session.
- A new time picker: a grid of times in 5-minute steps, in one small popover, for every time setting.

### Changed

- The menu is new: a short glance list of your buddies, a tool row for Time block and Reminder, and a "Take a break" menu in the footer.
- Corner reminders that do not fit on the screen start a new column to the left.
- Floating cards have no shadow.
- Each buddy reminds you on its own. Two reminders can show at once, stacked in the top-right corner of the display with your mouse pointer. Only one lock shows at a time.

### Fixed

- On macOS 27, no reminder showed, and "Show a reminder now" did nothing.
- Settings: chips, the sidebar, and the daily goal no longer wrap or clip, option cards have the same height, and the window has no empty strip at the bottom.
- Settings uses less memory, because text fields load only when you tap them.
- A breathing session fills all its minutes.

## [2.0.1] - 2026-10-25

### Added

- Website: <https://sumonta056.github.io/sathi-app/>.
- Each release now has a `Sathi.dmg` download that always points to the newest version.

### Fixed

- Menu bar: a long buddy name or reminder time no longer breaks across lines. The time moves under the name when the row is too narrow.
- Reports: the streak calendar shows every day of the month. Before, it lost the first days.

## [2.0] - 2026-10-25

Sathi 2.0 is a full redesign of the menu bar app, with a new Night theme and two new buddies.

### Added

- **Shanti** (meditation, off by default): guided breathing sessions (box, relax, or even) in the morning, afternoon, or evening.
- **Boi** (reading): a calm popup in the top-right corner that never takes focus. Start a timer, and Boi counts the minutes.
- **Reports window**: each habit by day, week, or month, with a chart, a streak calendar, and your best day.
- **Export**: save your history as CSV, or as a JSON backup.
- **Menu bar popover**: today's progress rings, your streak, and buttons to pause reminders.
- **Night theme**: a new Settings window, a dark water bubble, and a new app icon.

### Changed

- Data now lives in JSON files in `~/Library/Application Support/Sathi/`. On first launch, Sathi 2.0 moves your 1.0 data from UserDefaults and keeps the old data as a backup.
- Sathi keeps settings and events that come from a newer version.
- Lower idle CPU use.

[Unreleased]: https://github.com/Sumonta056/sathi-app/compare/v3.0.0...HEAD
[3.0.0]: https://github.com/Sumonta056/sathi-app/compare/v2.0.1...v3.0.0
[2.0.1]: https://github.com/Sumonta056/sathi-app/compare/v2.0...v2.0.1
[2.0]: https://github.com/Sumonta056/sathi-app/releases/tag/v2.0
