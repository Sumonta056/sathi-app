# Sathi

Sathi is a macOS menu bar app (macOS 13+, Swift 5.9 tools, SwiftUI + AppKit). Three buddies remind the user: Fota (water), Boi (reading), and Shanti (meditation, off by default). An ignored reminder escalates: bubble → persistent bubble → full-screen lock (water only). Reading and meditation use a calm corner popup that never takes focus.

## Commands

| Task | Command |
|---|---|
| Build (debug) | `swift build` |
| Run all tests | `./scripts/test.sh` |
| Run one target or suite | `./scripts/test.sh SathiCoreTests` or `./scripts/test.sh "Engine flows"` |
| Lint and file-size check | `./scripts/lint.sh` (add `--fix` to auto-format) |
| Build, install, open | `./build.sh --install` |
| Performance budget | `./scripts/perf.sh` (needs the app running) |
| Memory leak check over windows | `./scripts/perf.sh --windows` (user runs it in Terminal) |
| Make a DMG installer | `./scripts/make-dmg.sh` → `build/Sathi-<version>.dmg` and `build/Sathi.dmg`. Copy to the project root. `*.dmg` is git-ignored. |
| Website screenshots | `SATHI_SHOTS="$PWD/site/screenshots" swift test --filter WebsiteShots` |
| Check the website files | `./scripts/check-site.sh` |

## Module map

```
Sources/
  SathiCore/     Foundation only. All logic. Fully unit-tested.
    Models/        HabitID, Strictness, Container, Mood, Prefs, GeneralPrefs, LiveState, HistoryEvent, Persisted, ReminderState, GoalText, Set+KeepOne, DecodingDefaults, Calendar+Days, Date+WholeSecond
    Habits/        HabitRules, DayClock, one folder per habit: Water/, Reading/, Meditation/ (prefs, rules, helpers such as Weekday, BreathingPattern)
    Constants/     Timing, Limits, StorageKeys, SoundName
    Scheduling/    EscalationPolicy (bubble/lock), TickPlanner (timer delay)
    Stats/         Stats (daily totals), StreakCalculator, ReportBuilder + Report, ReportScreen + ReportScreenInput, ReportScreenBuilder (+Tiles, +Chart, +Calendar, +Text)
    Export/        CSVExporter, JSONExporter (backup), ExportNames, ExportFormat, ExportJob, ExportOutcome
    Formatting/    Fmt, Copywriter (+Reading, +Meditation)
    Ports/         Clock, StateStore, HistoryStore, SoundPlayer, ReminderPresenter, FileExporter, SummaryRenderer
    Storage/       JSONFiles, FileSlot, FileStateStore, FileHistoryStore, MonthEvents, RawJSON, LegacyMigrator, Legacy/ (v1 shapes)
    Engine/        Engine (+Loop, +Actions, +Session, +Corner, +Display, +Menu, +History, +Reports, +Export), StatusModel
  SathiUI/       SwiftUI + AppKit. Views and windows only.
    Constants/     UIMetrics (+Bubble, +Components, +Corner, +Lock, +Meditation, +Menu, +Reports, +Settings), TimeSlots
    Theme/         NightPalette (Night tokens), Typography, ButtonStyles, GhostButton, ProgressBar, Shake, ShakeSound, Color+Hex
    Components/    HeroCard, SettingsCard, SettingRow, OptionCard, ChipRow, SectionLabel, BuddySwitch
    Buddy/         BuddyView, BuddyCanvas (+Pebble), BuddyKind, BuddyInk, WaterInk, BuddyPaths, BobbingBuddy, GlassIcon, BottleView
    Features/      MenuBar/, Bubble/, Water/, Reading/, Meditation/, Session/, Celebrate/, Lock/, Settings/, Reports/
    Windows/       UIController (+Corner, +Placement; ReminderPresenter impl), PanelFactory, CornerToast, SettingsWindow, ReportsWindow, LockScreen, PanelWindows, WindowCloseWatcher
    Platform/      SystemSoundPlayer
  Sathi/         Executable. SathiApp, AppDelegate, AppEnvironment (composition root).
Resources/        Info.plist (version), AppIcon.icns (app icon), AppIcon.png (1024 px preview)
Tests/
  SathiTestSupport/  FakeClock, InMemoryStateStore, InMemoryHistoryStore, SpySoundPlayer, SpyPresenter, SpyFileExporter, SpySummaryRenderer, ThreadSpyHistoryStore, DecodedBackup, FixedZone, EngineHarness, TestFiles, day()
  SathiCoreTests/    Swift Testing unit tests for every Core module
  SathiUITests/      ViewInspector tests for views + engine interaction
docs/             ROADMAP.md, specs/ (one spec per phase), design/ (design reference PNGs)
site/             GitHub Pages website: index.html, site.css, screenshots/, og.png, robots.txt, sitemap.xml, 404.html
.github/          workflows/ ci.yml (lint, test, site check), pages.yml (deploy site/), release.yml (tag → DMG on GitHub Release)
```

Data lives in `~/Library/Application Support/Sathi/`: `prefs.json`, `state.json`, `history/YYYY-MM.json`.

Dependency direction: `Sathi → SathiUI → SathiCore`. Never the other way.

## Rules

Detailed rules live in `.claude/rules/`. They load when you touch matching files. The short version:

1. **No code comments** unless the user asks. SwiftLint enforces it (`no_comments`).
2. **One job per file. Max 200 lines per file.** `scripts/lint.sh` fails above 200. Split before you reach it.
3. **No magic numbers for behavior.** Durations go in `Constants/Timing.swift` or `UIMetrics.swift`. Ranges and thresholds go in `Constants/Limits.swift`. Storage keys go in `StorageKeys.swift`.
4. **SathiCore never imports AppKit or SwiftUI.** It talks to the outside through `Ports/`.
5. **Engine reads time only from `clock.now`.** Never `Date()` in Engine, Scheduling, or Stats.
6. **Use `package` access** for anything another target needs. Keep the rest `internal` or `private`.
7. **Performance budget:** idle CPU < 1%, memory footprint < 40 MB fresh and < 50 MB after a window, < 10 idle wakeups per minute. No repeating 1-second timers. Animations cap at 30 fps and pause when hidden.
8. **Tests first** for every behavior change. Use `EngineHarness` and fakes. No real waits.
9. **Business rules** live in `.claude/rules/business-logic.md`. Change that file before you change behavior.
10. **Storage:** never lose user data. Follow `.claude/rules/storage.md` and the `/data-migration` skill for any change to saved data.

## Workflow

- The plan lives in `docs/ROADMAP.md`. Use the `/roadmap` skill to see the next step and keep the roadmap current.
- Use the `/feature` skill for every change: plan → approval → failing tests → code → checks → review.
- Use the `/add-habit` skill to add a new habit (e.g. "stretch", "eyes").
- Use the `/perf-check` skill after any change to timers, animations, or published state.
- Use the `/data-migration` skill to add a saved field or bump the schema.
- Use the `ui-verifier` agent to compare the running app with `docs/design/`.
- Use the `/make-dmg` skill to build a DMG on this Mac (optional signing and notarization).
- Use the `/sathi-release` skill to cut a release: version, changelog, tag, and the DMG on the GitHub Release.
- Use the `/sathi-website` skill after a user-visible change: site text, screenshots, SEO tags, and README.
- Ask before every `git commit` and `git push`. `main` is protected by a hook. Work on a branch.

## Definition of done

1. `./scripts/test.sh` passes.
2. `./scripts/lint.sh` passes.
3. `swift build -c release` passes with no new warnings.
4. For UI, timer, or animation changes: `./build.sh --install` then `./scripts/perf.sh` passes. For window changes the user also runs `./scripts/perf.sh --windows` in Terminal.
5. README and this file are updated if commands, modules, or rules changed.
6. For user-visible changes: the website and its screenshots are updated (`/sathi-website`).
