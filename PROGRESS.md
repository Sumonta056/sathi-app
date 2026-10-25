# Sathi 2.0 redesign: progress and handover

Read this file first in a new session. It holds everything needed to continue from Phase 5.

## How to resume

Paste this as the first message of the new session:

> Read `PROGRESS.md`, `docs/ROADMAP.md`, `CLAUDE.md`, and `.claude/rules/business-logic.md`. Then continue the Sathi 2.0 redesign from Phase 6, on branch `feature/redesign-v2`, with the subagent workflow in `PROGRESS.md`.

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
| `1fe3a64` | 5a–5c: Night theme, Settings window, menu bar popover, review fixes |
| `7a583e4` | 5d–5f: water bubble, reading corner popup, breathe view, review fixes |

### Checks at the end of 5d–5f (2026-10-25)

- `./scripts/test.sh`: 686 tests pass (UI 216 in 30 suites, Core 470 in 71 suites). The script prints two lines; add them.
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

## Phase 5: UI redesign (in progress)

Status (2026-10-25): 5a–5f are done, reviewed, and committed (`1fe3a64` for 5a–5c, `7a583e4` for 5d–5f). 5g Reports window is done, reviewed, review fixes G1–G9 done, green (779 tests: UI 240, Core 539), **not committed**. 5g2 done (Lock and legacy views on `Night`, `BuddyInk`, `Palette` deleted; 790 tests: UI 251, Core 539; spec `phase-5g2-palette.md`), not committed. 5h done (2026-10-25): idle 0.0% CPU, 17 MB, 0 wakeups; Reports open 0.3% CPU; memory ~40–42 MB after any first window (one-time, budget now < 50 MB); Export menu removed (save panel wakeups). 780 tests (UI 241, Core 539). Committed as the 5g–5h commit. Still open: visual check of 5d–5f screens, Reports, and the re-themed Lock screen in the running app. Next: Phase 6. Specs: `phase-5g-reports.md`, `phase-5g-review-fixes.md`.

- 5a–5c: the user checked the installed app on 2026-10-25 (OK). Defaults backup: `~/Desktop/sathi-defaults-backup.plist`; real data is migrated to the JSON files.
- 5d–5f: **never checked in the running app.** Check in 5h: the look of each screen, a single click on corner buttons (non-key panel, `FirstClickHostingView`), panel sizes (`sizingOptions = []`, `UIMetrics.calmNoteHeight` 16 is a guess), and CPU while a bubble or the breathe view is open.
- User choices in 5d–5f: keep the drag bottle; water thank-you top-right; reading snooze = General length; "Stop" never counts an early stop (reading and meditation); 4 s "Boi comes back" note; Nudgy reading and meditation wiggle in silence; the meditation invite never takes focus; "See you after your break" / "Nice one"; cap loop animations at 30 fps now; accept the last partial breathing round.
- Specs: `docs/specs/phase-5a-theme.md`, `phase-5b-settings.md`, `phase-5c-menubar.md`, `phase-5abc-review-fixes.md`, `phase-5d-water-bubble.md`, `phase-5e-reading-corner.md`, `phase-5f-meditation.md`, `phase-5df-review-fixes.md`.
- Commit approval per group (5a–5c done, 5d–5f done, 5g–5h next). Full review for 5g.
- Theme: `Night` (old `Palette` stays until 5g deletes it), `Typography`, `Components/`. Cards: `WaterCard`, `CornerCard`, `CalmCard`. Loop animations: `BobbingBuddy`, `SparkBurst`, `BreathCircle` (TimelineView, 30 fps, pure tested functions). Windows: `PanelFactory`, `CornerToast`/`CornerPanel`, `UIController+Placement`, `UIController+Corner`.
- Legacy views still in use: `LegacyBubble` (reading focus style), `SessionView` (reading focus style), `LegacyCelebrate` (reading focus style). 5g must decide what to do with them when it deletes the old `Palette`.

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

- SwiftUI implicit animations (`withAnimation`, `.repeatForever`, long `.linear`) run on the main thread at the full screen rate (60–120 Hz) with no cap. Do not use them for loops or for anything longer than a short transition. (The 5d/5f review found this; the earlier note here was wrong.)
- For a loop (bob, spark, breathe), use one `TimelineView(.animation(minimumInterval: UIMetrics.animationFrameInterval, paused: hidden || reduceMotion))` and compute the value from the date with a pure, tested function. For a slow bar, use `TimelineView(.periodic(by: 0.5))`.
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

### Time estimate for Phase 5 (told to the user on 2026-10-24)

About 4–5 hours of agent work, plus the user's answers and approvals. Phases 1–4 took 30–60 minutes each, including review fix rounds.

| Slice | Estimate |
|---|---|
| 5a Theme | 20–30 min |
| 5b Settings window | 45–60 min |
| 5c Menu bar popover | 25–35 min |
| 5d Water bubble | 25–35 min |
| 5e Reading corner popup | 30–40 min |
| 5f Meditation | 25–35 min |
| 5g Reports window | 45–60 min |
| 5h Perf check | 15–30 min |

Risks: a visual fix round after the user sees a screen adds 10–20 minutes per slice. A perf problem adds about 30 minutes.

Ways to go faster (offer them to the user at the start; do not apply them without a yes):

- One commit approval per group of slices (for example 5a–5c) instead of one per slice. Saves about 30 minutes.
- A full review only for slices with logic (5e, 5g). One review pass for the pure view slices. Saves about 45 minutes.

Each slice is its own commit, so the user gets usable screens early (the new Settings window after 5b).

### 5g start checklist

1. `git status` (only `Feature.md` untracked) and `git log --oneline -3` (top is the handover update after `7a583e4`).
2. `./scripts/test.sh` → 686 pass (UI 216 + Core 470); `./scripts/lint.sh` → Lint OK.
3. Read the Reports artboard (`project/Stats.dc.html`) on the design canvas before you write the 5g spec.
4. Write `docs/specs/phase-5g-reports.md` (decide `FileExporter` on `@MainActor`, export off the main actor, error UI), link it in `docs/ROADMAP.md`, ask the user about open product points, then run the workflow.

## Phase 6: Claude setup

Status (2026-10-25): done, reviewed (1 blocker, 5 major fixed), not committed. Spec `docs/specs/phase-6-claude-setup.md`. Design PNGs in `docs/design/` (render steps in its README). A dry run of `/add-habit stretch` found 16 gaps in the skill; all fixed. Tests 780 (UI 241, Core 539), lint OK. Committed as `30a8590`.

6b tolerant decoding (2026-10-25): unknown `strictness`/`container` fall back to defaults; unknown history events and unknown event fields are kept and written back (`RawJSON`, `MonthEvents`). Business rule History and storage 8. Spec `phase-6b-tolerant-decoding.md`. 799 tests (UI 241, Core 558). Next: Phase 7.

- Rewrite `.claude/skills/add-habit/SKILL.md` for the module layout: one folder per habit in Core (`Habits/<Name>/`: prefs, rules) and UI (`Features/<Name>/`: settings tab, reminder view), the exhaustive switches the compiler finds, `Prefs`/`scheduleKey`/decoding defaults, Copywriter, Palette, BuddyKind, tests per step.
- New `.claude/rules/storage.md` (paths `Sources/SathiCore/Storage/**`, `Models/**`): file layout, `schemaVersion`, whole-second times, decoding defaults, migration marker, never overwrite unreadable files, retry failed writes, fixture tests for every migration.
- New skill `.claude/skills/data-migration/SKILL.md`: how to add a field or bump the schema, with a fixture test and a re-run test.
- New agent `.claude/agents/ui-verifier.md` (read-only): launch the app, screenshot each window, compare with the canvas artboards, report differences.
- Update `test-writer.md` and `.claude/skills/write-unit-tests/SKILL.md`: temp-folder file tests with `flush()`, permission-based failure tests with `defer` restore, `InMemoryHistoryStore`, `SpyFileExporter`, `FixedZone` calendars, proving red in a scratch copy.
- Update `perf-auditor.md` and `scripts/perf.sh`: memory must return to baseline after the Reports and Settings windows close.

## Phase 7: Docs and release check

Status (2026-10-25): README, CLAUDE.md, and architecture.md updated and reviewed. Version 2.0 (build 2) installed; idle perf PASS (0.0% CPU, 18 MB, 0 wakeups). `Sathi-2.0.dmg` built (ad-hoc). Open: the user runs `./scripts/perf.sh --windows` in Terminal; the visual check of 5d–5f, Reports, and Lock (use `ui-verifier`). Next: PR from `feature/redesign-v2` to `main`.

- Update `README.md` and `CLAUDE.md` (module map, storage location, commands, rules).
- Run the Definition of done in `CLAUDE.md`: tests, lint, release build without warnings, `./build.sh --install` + `./scripts/perf.sh`.
- Optionally bump the version in `Resources/Info.plist` and use `/make-dmg`.
- Then ask the user about a PR from `feature/redesign-v2` to `main`.

## Later (from reviews; not scheduled)

See the Later list in `docs/ROADMAP.md`. Short version: Morning dew light theme, real Stretch/Eyes/Walk/Posture modules, timestamped `.corrupt` names, whole-second rule enforced by types, merge v1 `streakReset` on a migration re-run, pause plus settings change behavior, queued habit after its due moved forward, `BreathingPattern` with infinite elapsed time, `percentOfGoal` rounding (99.5 → 100), streak window if the clock goes back across a month, `windowStart` on the system calendar, menu subtitle `now` vs `clock.now` after midnight.
