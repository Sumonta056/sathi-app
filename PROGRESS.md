# Sathi 2.0 redesign: progress and handover

Read this file first in a new session. It holds everything needed to continue from Phase 5.

## How to resume

Paste this as the first message of the new session:

> Read `PROGRESS.md`, `docs/ROADMAP.md`, `CLAUDE.md`, and `.claude/rules/business-logic.md`. Then continue the Sathi 2.0 redesign from Phase 5, slice 5a, on branch `feature/redesign-v2`, with the subagent workflow in `PROGRESS.md`.

## Where things are

| Item | Value |
|---|---|
| Branch | `feature/redesign-v2` (not pushed; `main` is protected) |
| Design canvas | https://claude.ai/artifact/AgF243uMtC5H8ySBfdXx6e (6 artboards: Settings, Reports, Menu bar, Water bubble, Reading corner popup, Meditation) |
| Roadmap | `docs/ROADMAP.md` (checkboxes, Later list, Decisions table) |
| Business rules | `.claude/rules/business-logic.md` (change it before you change behavior) |
| Phase specs | `docs/specs/phase-2-storage.md`, `phase-3-meditation.md`, `phase-4-reports.md` |
| Untracked | `Feature.md` (the user's own notes; never commit or delete it) |

### Commits on the branch

| Commit | Phase |
|---|---|
| `57e74b1` | 0: business rules, roadmap, `/roadmap` skill |
| `5f65fca` | 1: per-habit rules modules (`HabitRules`, `WaterRules`, `ReadingRules`, `DayClock`) |
| `e314293` | 2: JSON file storage, migration from UserDefaults, hardening |
| `e7fb953` | 3: Meditation habit (Shanti), breathing sessions, review fixes |
| `d387ab0` | 4: reports, streaks across months, CSV and JSON export, review fixes |

### Checks at the end of Phase 4

- `./scripts/test.sh`: 402 tests pass (Core 359 in 53 suites, UI 43 in 6 suites). The script prints two lines; add them.
- `./scripts/lint.sh`: Lint OK.
- `swift build -c release`: no warnings.
- `/perf-check`: not run since the redesign started (it is planned for slice 5h; see the warning below).

## What exists now (Core)

- **Habits:** `HabitID` = water, reading, meditation. Each habit is a module in `Sources/SathiCore/Habits/<Name>/` (rules + prefs). Every `switch` on `HabitID` is exhaustive with no `default:`; a new habit fails to compile until every place handles it.
- **Storage:** `~/Library/Application Support/Sathi/` → `prefs.json`, `state.json`, `history/YYYY-MM.json`, `migrated-v1` marker. Atomic, coalesced writes (`Timing.saveCoalesce`), `flush()` on quit. Corrupt files move to `.corrupt`; unreadable files are never overwritten. Stored times are whole seconds. `LegacyMigrator` moves the old `sathi.state.v1` UserDefaults blob once.
- **Engine:** one `HabitState` per habit, `Phase.session(HabitID)` shared by Reading and Meditation, every done/snooze/skip recorded as a `HistoryEvent`, 3 months of events in RAM.
- **Calendar:** `Calendar.gregorian(in:)` and DST-safe day steps (`Models/Calendar+Days.swift`). Storage, reports, and export always use Gregorian dates in the user's time zone.
- **Reports (Phase 4):** `ReportBuilder` (day/week/month buckets, average, % of goal, days met, best day, snoozes), `StreakCalculator` (current and longest, reads older month files on demand), `CSVExporter`, `JSONExporter`, `ExportNames`, `FileExporter` port, `Engine.report(_:)`, `Engine.longestStreak(_:)`, `Engine.export(_:to:)`.
- **UI today:** the old screens, plus minimum Meditation UI (simple Shanti drawing, "Breathe" button, breathing text in the session window, Meditation section in the old Settings form). Phase 5 replaces this.

## The workflow (the user asked for it; keep it)

Each phase, or each slice of Phase 5, runs these steps. The main session coordinates and verifies; subagents do the work.

1. **Spec first.** Write `docs/specs/phase-N-<name>.md` with the exact API, behavior, constants, and a "Tests that define done" list. Link it in `docs/ROADMAP.md`. Update `.claude/rules/business-logic.md` first when behavior changes.
2. **Red.** Spawn the `test-writer` agent with the spec. It writes only under `Tests/` and proves in a scratch copy that tests fail on assertions. Then run `swift build --build-tests` yourself and check that only the missing API breaks the build.
3. **Green.** Spawn a `general-purpose` implementer with the spec and the test list. Rules in its brief: no edits under `Tests/`, no comments, ≤200 lines per file, ≤150 per type body, no magic numbers, no commit.
4. **Check yourself:** `./scripts/test.sh` (two runs: Core and UI; add both totals), `./scripts/lint.sh`, `swift build -c release`. For UI, timer, animation, or window changes also `/perf-check` (see the warning below).
5. **Review.** Spawn the `code-reviewer` agent with a list of attack points. Fix every BLOCKER (tests first). Ask the user about product decisions with AskUserQuestion. Record the rest in the roadmap's Later list.
6. **Commit** only after the user says yes. End the message with the `Claude-Session:` line from the system reminder. Tick the roadmap boxes first.

Every agent brief starts with: "Right after you read the brief, call the savvy-progress `step` tool with your plan as `total` (3 to 8 steps) and `done: 0`. Call it again with the new `done` and a short `note` after each step."

The user's global rules: plan before code and wait for approval, ask before each significant step, never commit without a clear yes, no code comments, explain like to a junior developer, write in Simplified Technical English.

### Warnings

- **`/perf-check` touches the user's real data.** It installs the release build, and the first launch migrates the real UserDefaults data to the new files. Ask the user first. Before the install, back up the old data: `defaults export <bundle id> ~/Desktop/sathi-defaults-backup.plist` (read the bundle id from `Resources/Info.plist`).
- **Stop hook:** `.claude/hooks/require-tests.sh` fails the turn while tests are red. During the red step that is expected; say so and continue.
- **Blast Radius hook:** it may hold a shell command whose text contains words like "migrate". If it blocks one, do not retry until the user says so.

## Decisions already made (do not ask again)

All rows of the Decisions table in `docs/ROADMAP.md` hold. The ones that shape Phase 5:

- Font: SF Rounded (`.rounded` design). No bundled font.
- Theme: "Night sprout" dark only. Light theme ("Morning dew") is in Later.
- "Add a buddy" tab shows coming-soon cards (Stretch, Eye break, Walk, Posture) with a disabled "Soon" button.
- Reading reminder: a small non-activating popup in the top-right corner that never blocks work. "Focus screen" (the old centered session) stays as an option in the Reading tab.
- Reading and Meditation never lock. Only Water shows "Strict".
- Meditation is off by default.
- A stop with nothing due does nothing. A settings change never fires a past slot.
- Storage: monthly JSON, history kept forever, 3 months in RAM.

## Phase 5: UI redesign (next)

Goal: build the canvas design in SwiftUI, slice by slice. Each slice is one `/feature` loop and one commit. UI tests use ViewInspector; logic stays in Core.

### Theme tokens (from the canvas)

| Token | Hex | Use |
|---|---|---|
| `bg` | `#121826` | window background |
| `sidebar` | `#0D1220` | sidebar, title bar, segmented track |
| `card` | `#1A2233` | cards |
| `border` | `#263049` | card borders, empty meters |
| `divider` | `#222B40` | row dividers |
| `text` | `#EEF2FA` | main text |
| `muted` | `#9AA6BF` | hints |
| `label` | `#8C99B3` | section labels (uppercase, letter spacing) |
| `faint` | `#6F7C97` | small labels |
| `water` | `#4CC3F5` | Fota; hero card `#15263A`, border `#1F3D5A` |
| `reading` | `#F2A64A` | Boi; hero card `#2A2219`, border `#4A3720` |
| `calm` | `#A99CF5` | Shanti; hero card `#211F38`, border `#37335C`; bubble ground `#16142A` |
| `sprout` | `#5FD39A` | app-wide actions, streak, logo |
| `cheek` | `#FF9FB8`, `spark` `#FFC94A` | buddy details, celebration |

Text on an accent button is `#0D1220`. Corner radius: cards 16, buttons 10–12, chips full pill. Check contrast 4.5:1 for text.

### Animation and performance rules for Phase 5

- No new `TimelineView(.animation)`. Use SwiftUI implicit animations with `.repeatForever` (bob, blink, breathe), which run in the render server.
- Respect `@Environment(\.accessibilityReduceMotion)`: no motion when it is on.
- Animations stop when a window closes (windows close with `orderOut` and drop the reference).
- Budget: idle CPU < 1%, memory < 40 MB, < 10 idle wakeups per minute (`.claude/rules/performance.md`).

### Slices (in order)

| Slice | Content | Main files |
|---|---|---|
| 5a Theme | `Theme/Palette.swift` night-sprout tokens (table above), `Theme/Typography.swift` (SF Rounded sizes), shared parts: `ChipRow`, `OptionCard`, `BuddySwitch` (bouncy toggle), `SectionLabel`, `HeroCard` | `Sources/SathiUI/Theme/`, `Sources/SathiUI/Components/` |
| 5b Settings window | 860×620 window: sidebar (General, Water, Reading, Meditation "New", Add a buddy, "Open reports"); a switch per buddy in the sidebar; tabs with hero card + sections. Water: interval chips, hours, cup, daily-goal glasses row, ignore cards (Gentle/Nudgy/Strict). Reading: time, weekdays, length chips, "How Boi says hi" (Corner popup / Focus screen), ignore cards (Gentle/Nudgy). Meditation: slots, length, chime, breathing style cards. General: name, theme cards (Night only active), login, sounds, quiet in meetings. A buddy that is off fades its tab content. | `Features/Settings/` |
| 5c Menu bar popover | Greeting + streak, one row per enabled habit with a progress ring and its action ("+1 glass", "Read now", "Breathe"), a "sleeping" row for a disabled module, pause chips (30 min / 1 hour / rest of day), icon footer (Reports, Settings, Quit) | `Features/MenuBar/` |
| 5d Water bubble | Dark card, Fota bobbing, 3 amount cards with glass fill, Glass / Sip bottle segment, Snooze, ignore bar; thank-you state with drops row | `Features/Bubble/` |
| 5e Reading corner popup | New non-activating panel in the top-right (`Windows/CornerToast`): invite card → timer pill with ring → done card; "In 10 min" snoozes. Never takes focus. The old centered session is used only when the Reading tab picks "Focus screen". | `Windows/`, `Features/Reading/` |
| 5f Meditation | `BreatheView`: invite → glowing circle that grows and shrinks with `BreathingPattern` phases (text "Breathe in / Hold / Breathe out / Rest"), round counter, "I am done"; proper Shanti drawing in `BuddyCanvas` | `Features/Meditation/`, `Buddy/` |
| 5g Reports window | 860×620: Day/Week/Month segment, one tile per habit (value, unit, meter, % of goal; tap selects), bar chart with dashed goal line (Swift Charts, macOS 13), October streak calendar, best day / snoozes / longest streak, Export menu: CSV, JSON (Core), PDF summary (render a SwiftUI page with `ImageRenderer` into a PDF context). `NSSavePanel` implements `FileExporter` in SathiUI. Decide whether `FileExporter` becomes `@MainActor` (the panel needs the main thread). Build export data off the main actor and show an error when saving or encoding fails (both silent today). | `Features/Reports/`, `Platform/` |
| 5h Perf | `/perf-check` on the installed build (ask first, back up defaults). Open and close each window and check CPU returns to ~0%. | — |

For each slice, the spec must name every new view, the Engine calls it makes, the strings tests look for, and the constants it adds to `UIMetrics`.

## Phase 6: Claude setup

- Rewrite `.claude/skills/add-habit/SKILL.md` for the module layout: one folder per habit in Core (`Habits/<Name>/`: prefs, rules) and UI (`Features/<Name>/`: settings tab, reminder view), the exhaustive switches the compiler finds, `Prefs`/`scheduleKey`/decoding defaults, Copywriter, Palette, BuddyKind, tests per step.
- New `.claude/rules/storage.md` (paths `Sources/SathiCore/Storage/**`, `Models/**`): file layout, `schemaVersion`, whole-second times, decoding defaults, migration marker, never overwrite unreadable files, retry failed writes, fixture tests for every migration.
- New skill `.claude/skills/data-migration/SKILL.md`: how to add a field or bump the schema, with a fixture test and a re-run test.
- New agent `.claude/agents/ui-verifier.md` (read-only): launch the app, screenshot each window, compare with the canvas artboards, report differences.
- Update `test-writer.md` and `.claude/skills/write-unit-tests/SKILL.md`: temp-folder file tests with `flush()`, permission-based failure tests with `defer` restore, `InMemoryHistoryStore`, `SpyFileExporter`, `FixedZone` calendars, proving red in a scratch copy.
- Update `perf-auditor.md` and `scripts/perf.sh`: memory must return to baseline after the Reports and Settings windows close.

## Phase 7: Docs and release check

- Update `README.md` and `CLAUDE.md` (module map, storage location, commands, rules).
- Run the Definition of done in `CLAUDE.md`: tests, lint, release build without warnings, `./build.sh --install` + `./scripts/perf.sh`.
- Optionally bump the version in `Resources/Info.plist` and use `/make-dmg`.
- Then ask the user about a PR from `feature/redesign-v2` to `main`.

## Later (from reviews; not scheduled)

See the Later list in `docs/ROADMAP.md`. Short version: Morning dew light theme, real Stretch/Eyes/Walk/Posture modules, timestamped `.corrupt` names, whole-second rule enforced by types, merge v1 `streakReset` on a migration re-run, pause plus settings change behavior, queued habit after its due moved forward, `BreathingPattern` with infinite elapsed time, `percentOfGoal` rounding (99.5 → 100), streak window if the clock goes back across a month, `windowStart` on the system calendar, menu subtitle `now` vs `clock.now` after midnight.
