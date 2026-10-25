# Changelog

All user-visible changes to Sathi. Each version has a tag `vX.Y.Z` and a GitHub Release with the DMG.

## [Unreleased]

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

[Unreleased]: https://github.com/Sumonta056/sathi-app/compare/v2.0.1...HEAD
[2.0.1]: https://github.com/Sumonta056/sathi-app/compare/v2.0...v2.0.1
[2.0]: https://github.com/Sumonta056/sathi-app/releases/tag/v2.0
