# Sathi

A menu bar app with two buddies that won't let you skip:

- **Fota** (water): pops up every 2 hours between 9:30 and 18:30. Log with a glass (a few sips / half / full) or drag the line on your sip bottle.
- **Boi** (reading): pops up at 22:00 and only counts when a 15-minute reading timer finishes.

If you ignore a buddy it escalates: popup → stays on top and shakes → (Strict) full-screen lock you unlock by holding a button for 3 seconds.

## Install (one time, about 1 minute)

Needs macOS 13 Ventura or newer.

1. Install Apple's command line tools if you don't have them:
   ```
   xcode-select --install
   ```
2. Unzip this folder, open Terminal in it, and run:
   ```
   chmod +x build.sh
   ./build.sh --install
   ```
3. A drop appears in your menu bar. Open **Settings…** from it and turn on **Open Sathi when my Mac starts**.

To test right away: Settings → **Show water reminder now**. Snooze twice to see the lock screen.

## Change things

Everything (times, interval, glass/bottle, bottle size, goal, strictness, snooze length, sound) is in Settings. Data is stored locally in UserDefaults (`com.mridul.sathi`).

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
| Make a DMG installer | `./scripts/make-dmg.sh` → `build/Sathi-<version>.dmg` |

## Share the app

`./scripts/make-dmg.sh` builds `build/Sathi-<version>.dmg`. The version comes from `CFBundleShortVersionString` in `Resources/Info.plist`.

The default build is ad-hoc signed. On another Mac, right-click Sathi.app and choose **Open** the first time. For a public download, sign and notarize with an Apple Developer ID:

```
xcrun notarytool store-credentials sathi-notary
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" NOTARY_PROFILE=sathi-notary ./scripts/make-dmg.sh
```

## Structure

- `Sources/SathiCore`: models, schedule, escalation, stats, copy, and the `Engine` state machine. No AppKit or SwiftUI.
- `Sources/SathiUI`: SwiftUI views (one feature per folder), buddy drawings, theme, and window management.
- `Sources/Sathi`: the app entry point and composition root.
- `Tests/`: Swift Testing unit tests, ViewInspector UI tests, and shared fakes.

`CLAUDE.md` has the full module map, rules, and definition of done. To add a habit, follow `.claude/skills/add-habit/SKILL.md`.
