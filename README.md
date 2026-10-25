<p align="center">
  <img src="https://raw.githubusercontent.com/Sumonta056/sathi-app/main/site/icon.png" alt="Sathi app icon" width="96" height="96" />
</p>

<h1 align="center">Sathi</h1>

<p align="center">
  A free macOS menu bar app with three buddies that remind you to <b>drink water</b>, <b>read</b>, and <b>meditate</b>.
</p>

<p align="center">
  <a href="https://github.com/Sumonta056/sathi-app/releases/latest/download/Sathi.dmg"><b>Download for Mac</b></a> ·
  <a href="https://sumonta056.github.io/sathi-app/">Website</a> ·
  <a href="https://github.com/Sumonta056/sathi-app/blob/main/CHANGELOG.md">What is new</a>
</p>

<p align="center">
  <a href="https://github.com/Sumonta056/sathi-app/releases/latest"><img src="https://img.shields.io/github/v/release/Sumonta056/sathi-app?label=release" alt="Latest release" /></a>
  <a href="https://github.com/Sumonta056/sathi-app/actions/workflows/ci.yml"><img src="https://github.com/Sumonta056/sathi-app/actions/workflows/ci.yml/badge.svg" alt="CI status" /></a>
  <img src="https://img.shields.io/badge/macOS-13%2B-blue" alt="macOS 13 or newer" />
  <a href="https://github.com/Sumonta056/sathi-app/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-green" alt="MIT license" /></a>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/Sumonta056/sathi-app/main/site/screenshots/menu-bar.png" alt="Sathi menu bar popover with progress rings for water, reading, and meditation, a 9-day streak, and buttons to pause reminders" width="380" />
</p>

## Install

Needs macOS 13 Ventura or newer, on Apple silicon or Intel.

1. Download [`Sathi.dmg`](https://github.com/Sumonta056/sathi-app/releases/latest/download/Sathi.dmg) and drag Sathi to **Applications**.
2. Open Sathi once. Sathi is not notarized by Apple, so macOS asks first. Go to **System Settings → Privacy & Security** and click **Open Anyway**. On macOS 13 and 14 you can also right-click Sathi and choose **Open**.
3. A drop appears in your menu bar. Click it, then the gear icon. On the General tab, turn on **Open Sathi when I log in**.

To see a reminder right away, open Settings, pick a buddy, and click **Show a reminder now**.

## The buddies

- **Fota** (water): a reminder every 2 hours between 9:30 and 18:30. Log a few sips, half, or a full glass, or drag the line on your sip bottle. The daily goal is 8 glasses.
- **Boi** (reading): a small popup in the top-right corner at 22:00. It never takes focus from your work. Start a 15-minute timer, and Boi counts the minutes. Pick the days of the week.
- **Shanti** (meditation, off by default): a guided breathing session (box, relax, or even) in the morning, afternoon, or evening.

<p align="center">
  <img src="https://raw.githubusercontent.com/Sumonta056/sathi-app/main/site/screenshots/water-bubble.png" alt="Water reminder bubble with buttons for a few sips, half, and a full glass" width="440" />
  <img src="https://raw.githubusercontent.com/Sumonta056/sathi-app/main/site/screenshots/reading-corner.png" alt="Reading corner popup from Boi with Start reading and In 5 min buttons" width="378" />
</p>

## Reminders that escalate

If you ignore a reminder, it gets firmer, step by step:

| Level | What happens |
|---|---|
| Gentle | A reminder each time. It never stays on top. |
| Nudgy | After 1 snooze, the reminder stays on top and wiggles. |
| Strict (water only) | After 2 snoozes, a full-screen lock. Hold a button for 3 seconds to unlock. An emergency skip is always there. |

Reading and meditation never lock the screen. The menu bar popover can pause all reminders for 30 minutes, 1 hour, or the rest of the day.

<p align="center">
  <img src="https://raw.githubusercontent.com/Sumonta056/sathi-app/main/site/screenshots/water-nudgy.png" alt="Nudgy water reminder after 1 snooze, with no close button" width="400" />
  <img src="https://raw.githubusercontent.com/Sumonta056/sathi-app/main/site/screenshots/water-lock.png" alt="Strict full-screen lock with a Hold button and an Emergency skip link" width="420" />
</p>

See [every reminder on the website](https://sumonta056.github.io/sathi-app/#gallery): the thank-you cards, the reading timer, the breathing session, and more.

## Reports and settings

- The Reports window shows each habit by day, week, or month, with a chart, a streak calendar, your best day, and your longest streak.
- Each buddy has its own Settings page. Water: interval, active hours, container, goal, strictness. Reading: time, weekdays, session length, style, strictness. Meditation: time slots, session length, breathing style, chime.
- The General tab holds your name, snooze length, when no answer counts as a snooze, sound, and open at login.

<p align="center">
  <img src="https://raw.githubusercontent.com/Sumonta056/sathi-app/main/site/screenshots/reports.png" alt="Reports window with weekly averages, a water bar chart, and a streak calendar" width="640" />
</p>

## Privacy

Sathi makes no network requests. All data stays on your Mac in `~/Library/Application Support/Sathi/`:

| File | Holds |
|---|---|
| `prefs.json` | Settings |
| `state.json` | Live state (bottle level, last water time, streak resets) |
| `history/YYYY-MM.json` | Every done, snooze, and skip of one month, kept forever |

Sathi 1.0 kept data in UserDefaults (`com.mridul.sathi`). Sathi 2.0 moves it to these files once, on first launch, and keeps the old data as a backup for one release.

## Build from source

Needs Xcode 15 or newer. SwiftLint and SwiftFormat: `brew install swiftlint swiftformat`.

```sh
xcode-select --install
git clone https://github.com/Sumonta056/sathi-app.git
cd sathi-app
./build.sh --install
```

| Task | Command |
|---|---|
| Build | `swift build` |
| Run the app from source | `swift run` |
| All tests (unit + UI) | `./scripts/test.sh` |
| Lint and file-size check | `./scripts/lint.sh` (`--fix` to format) |
| Install the release app | `./build.sh --install` |
| CPU, memory, and wakeups budget | `./scripts/perf.sh` |
| Memory leak check over window open and close | `./scripts/perf.sh --windows` (run it in Terminal) |
| Make a DMG installer | `./scripts/make-dmg.sh` → `build/Sathi-<version>.dmg` and `build/Sathi.dmg` |
| Make the website screenshots | `SATHI_SHOTS="$PWD/site/screenshots" swift test --filter WebsiteShots` |
| Check the website files | `./scripts/check-site.sh` |

## Releases

A tag `vX.Y.Z` on `main` starts `.github/workflows/release.yml`. It checks that the tag matches `CFBundleShortVersionString` in `Resources/Info.plist` and that `CHANGELOG.md` has a section for the version. Then it runs the tests, builds the DMG, and attaches `Sathi-X.Y.Z.dmg` and `Sathi.dmg` to the GitHub Release.

The DMG is ad-hoc signed. To sign and notarize a local build with an Apple Developer ID:

```sh
xcrun notarytool store-credentials sathi-notary
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" NOTARY_PROFILE=sathi-notary ./scripts/make-dmg.sh
```

## Structure

- `Sources/SathiCore`: models, one module per habit (`Habits/<Name>/`), schedule, escalation, stats, reports, export, file storage, copy, and the `Engine` state machine. No AppKit or SwiftUI.
- `Sources/SathiUI`: the Night theme, shared components, SwiftUI views (one feature per folder), buddy drawings, and window management.
- `Sources/Sathi`: the app entry point and composition root.
- `Tests/`: Swift Testing unit tests, ViewInspector UI tests, and shared fakes.
- `site/`: the website, deployed to GitHub Pages by `.github/workflows/pages.yml`.
- `docs/`: the roadmap, the spec of each phase, and the design reference images.

`CLAUDE.md` has the full module map, rules, and definition of done. To add a habit, follow `.claude/skills/add-habit/SKILL.md`.

## License

[MIT](https://github.com/Sumonta056/sathi-app/blob/main/LICENSE) © Sumonta Saha Mridul
