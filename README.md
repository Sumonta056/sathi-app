# Sathi

A macOS menu bar app with three buddies that remind you to take care of yourself:

- **Fota** (water): a reminder every 2 hours between 9:30 and 18:30. Log a few sips, half, or a full glass, or drag the line on your sip bottle. The daily goal is 8 glasses.
- **Boi** (reading): a small popup in the top-right corner at 22:00. It never takes focus from your work. Start a 15-minute timer, and Boi counts the minutes when the timer ends. Pick the days of the week, or pick **Focus screen** for the old full-window session.
- **Shanti** (meditation, off by default): a guided breathing session (box, relax, or even) in the morning, afternoon, or evening.

If you ignore a reminder, it escalates. Gentle shows a reminder each time. Nudgy keeps it on top and wiggles it after 1 snooze. Strict (water only) also shows a full-screen lock after 2 snoozes. You unlock it by holding a button for 3 seconds. Reading and meditation never lock the screen.

The menu bar popover shows today's progress rings, your streak, and buttons to pause reminders for 30 minutes, 1 hour, or the rest of the day. The Reports window shows each habit by day, week, or month, with a chart, a streak calendar, and your best day.

## Install (one time, about 1 minute)

Needs macOS 13 Ventura or newer.

1. Install Apple's command line tools if you do not have them:
   ```
   xcode-select --install
   ```
2. Open Terminal in this folder and run:
   ```
   chmod +x build.sh
   ./build.sh --install
   ```
3. A drop appears in your menu bar. Click it, click the gear icon to open Settings, and on the General tab turn on **Open Sathi when I log in**.

To see a reminder right away: open Settings, pick a buddy, and click **Show a reminder now**.

## Settings and data

Each buddy has its own Settings tab. Water: interval, active hours, container, goal, strictness. Reading: time, weekdays, session length, style, strictness. Meditation: time slots, session length, breathing style, chime. The General tab holds your name, snooze length, when no answer counts as a snooze, sound, and open at login.

All data stays on your Mac in `~/Library/Application Support/Sathi/`:

| File | Holds |
|---|---|
| `prefs.json` | Settings |
| `state.json` | Live state (bottle level, last water time, streak resets) |
| `history/YYYY-MM.json` | Every done, snooze, and skip of one month, kept forever |

Sathi 1.0 kept data in UserDefaults (`com.mridul.sathi`). Sathi 2.0 moves it to these files once, on first launch, and keeps the old data as a backup for one release.

## Develop

Needs Xcode 15 or newer. SwiftLint and SwiftFormat: `brew install swiftlint swiftformat`.

| Task | Command |
|---|---|
| Build | `swift build` |
| Run the app from source | `swift run` |
| All tests (unit + UI) | `./scripts/test.sh` |
| Lint and file-size check | `./scripts/lint.sh` (`--fix` to format) |
| Install the release app | `./build.sh --install` |
| CPU, memory, and wakeups budget | `./scripts/perf.sh` |
| Memory leak check over window open and close | `./scripts/perf.sh --windows` (run it in Terminal) |
| Make a DMG installer | `./scripts/make-dmg.sh` → `build/Sathi-<version>.dmg` |

## Share the app

`./scripts/make-dmg.sh` builds `build/Sathi-<version>.dmg`. The version comes from `CFBundleShortVersionString` in `Resources/Info.plist`.

The default build is ad-hoc signed. On another Mac, right-click Sathi.app and choose **Open** the first time. For a public download, sign and notarize with an Apple Developer ID:

```
xcrun notarytool store-credentials sathi-notary
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" NOTARY_PROFILE=sathi-notary ./scripts/make-dmg.sh
```

## Structure

- `Sources/SathiCore`: models, one module per habit (`Habits/<Name>/`), schedule, escalation, stats, reports, export, file storage, copy, and the `Engine` state machine. No AppKit or SwiftUI.
- `Sources/SathiUI`: the Night theme, shared components, SwiftUI views (one feature per folder), buddy drawings, and window management.
- `Sources/Sathi`: the app entry point and composition root.
- `Tests/`: Swift Testing unit tests, ViewInspector UI tests, and shared fakes.
- `docs/`: the roadmap, the spec of each phase, and the design reference images.

`CLAUDE.md` has the full module map, rules, and definition of done. To add a habit, follow `.claude/skills/add-habit/SKILL.md`.
