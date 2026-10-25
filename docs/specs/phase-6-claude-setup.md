# Phase 6: Claude setup

Goal: Claude's skills, rules, and agents match the code after Phases 1–5. A new session that follows them makes the right change on the first try.

Phase 6 changes no Swift source. Only `scripts/perf.sh` is code.

## Decisions (2026-10-25)

| Topic | Decision |
|---|---|
| UI reference for `ui-verifier` | Render the 6 canvas artboards once to PNG in `docs/design/`. The agent compares with these files. It never opens the network. |
| Memory after windows | `perf.sh --windows` is a leak check: idle baseline, then 2 open-and-close cycles of Reports and Settings. Pass: every reading < 50 MB and cycle 2 adds < 3 MB to cycle 1. The ~23 MB first-window cost (5h) is expected. |
| Workflow | No red/green step. Writers in parallel, then a dry-run proof, then `code-reviewer`. One commit. |

## Facts every file must agree with

- `HabitID` (`Sources/SathiCore/Models/HabitID.swift`): `water`, `reading`, `meditation`. Every `switch` is exhaustive, no `default:`.
- Core module of a habit: `Sources/SathiCore/Habits/<Name>/` → `<Name>Prefs.swift`, `<Name>Rules.swift` (conforms to `HabitRules` in `Habits/HabitRules.swift`), plus helper types (example: `Reading/Weekday.swift`, `Meditation/BreathingPattern.swift`). Shared: `Habits/DayClock.swift`.
- UI module of a habit: `Sources/SathiUI/Features/<Name>/` → settings tab (`<Name>SettingsTab.swift`) and the reminder views. Water is the exception: its reminder views live in `Features/Bubble/` (`WaterBubble`, `WaterCard`, …) and its thank-you in `Features/Celebrate/WaterThanks.swift`.
- Files with a `switch` on `HabitID` today (the compiler finds them; the skill lists them as a check, not as the source of truth):
  - Core: `Models/HabitID.swift`, `Models/Prefs.swift`, `Models/Persisted.swift`, `Habits/HabitRules.swift`, `Formatting/Copywriter.swift`, `Engine/Engine+Actions.swift`, `+Corner`, `+Display`, `+Loop`, `+Menu`, `+Session`, `Stats/ReportScreenBuilder+Tiles.swift`.
  - UI: `Buddy/BuddyKind.swift`, `Theme/NightPalette.swift`, `Theme/ShakeSound.swift`, `Windows/UIController.swift`, `UIController+Corner.swift`, `Features/Bubble/BubbleView.swift`, `LegacyBubble.swift`, `Features/Celebrate/CelebrateView.swift`, `LegacyCelebrate.swift`, `Features/Lock/LockView.swift`, `Features/MenuBar/HabitCard.swift`, `Features/Session/SessionCopy.swift`, `Features/Settings/Engine+SettingsBindings.swift`, `SettingsSidebar.swift`, `SettingsView.swift`.
- Storage (`Sources/SathiCore/Storage/`): `JSONFiles`, `FileSlot`, `FileStateStore`, `FileHistoryStore`, `LegacyMigrator`, `Legacy/LegacyV1*.swift`. Decoding defaults: `Models/DecodingDefaults.swift`. Whole seconds: `Models/Date+WholeSecond.swift`.
- Test support (`Tests/SathiTestSupport/`): `EngineHarness`, `Fakes` (FakeClock, SpySoundPlayer, SpyPresenter), `InMemoryStores` (InMemoryStateStore, InMemoryHistoryStore), `ExportFakes` (SpyFileExporter), `FixedZone`, `TestFiles`, `ThreadSpyHistoryStore`.

Each writer reads the real files before it names a type, a function, or a path. A name in a doc that does not exist in the code is a bug.

## Work items

### W1. `.claude/skills/add-habit/SKILL.md` (rewrite)

- Keep the front matter `name` and the trigger words of `description`.
- Step 0 goes away (the ternaries and the `water`/`reading` properties are gone since Phase 1).
- Steps in order, each with its files and its tests:
  1. Business rules: add the habit's rows to `.claude/rules/business-logic.md` (schedule, done-when, may it lock).
  2. Core model: `HabitID` case (`name`, `buddy`), `Habits/<Name>/<Name>Prefs.swift` with decoding defaults, the field in `Prefs` and in `scheduleKey`, `Limits` ranges, `Timing` durations. Default off (Decision 2026-10-24: an update never starts a reminder the user did not ask for).
  3. Core rules: `<Name>Rules: HabitRules`, register it where `HabitRules` maps `HabitID` to rules.
  4. Build: `swift build` and fix each exhaustive `switch` the compiler reports. List the known sites above as a check.
  5. Copy: `Copywriter` lines for the new buddy.
  6. UI: `BuddyKind`, `Night` accent and hero colors (`NightPalette.swift`), settings tab in `Features/<Name>/`, sidebar entry, reminder view, thank-you.
  7. Storage: follow the `data-migration` skill (old files without the new fields must still decode).
  8. Remove the habit's "coming soon" card from `AddBuddyTab` if it has one.
  9. Checks from `CLAUDE.md` Definition of done, plus `/perf-check` if the reminder view animates.
- Name the test suites to add to for each step (read `Tests/` for the real names).

### W2. `.claude/rules/storage.md` (new)

Front matter `paths`: `Sources/SathiCore/Storage/**/*.swift`, `Sources/SathiCore/Models/**/*.swift`, `Tests/SathiCoreTests/**/*Storage*.swift` (check the real test file names and adjust the glob).

Rules (each one checked against the code):

1. Layout: `~/Library/Application Support/Sathi/` → `prefs.json`, `state.json`, `history/YYYY-MM.json`, `migrated-v1`.
2. Each file has `schemaVersion`. Name the type that holds it.
3. Writes are atomic and coalesced (`Timing.saveCoalesce`); `flush()` on quit.
4. Times are whole seconds (`Date+WholeSecond`).
5. Every new field decodes with a default (`DecodingDefaults`). A missing or unknown value never resets the other settings (business rule Schedules 9).
6. A corrupt file moves to `.corrupt`. An unreadable file is never overwritten.
7. A failed write is retried. Name where.
8. `LegacyMigrator` runs once, guarded by the marker, and a re-run never overwrites newer state.
9. Every migration and every new field has a fixture test with old JSON, and a re-run test.
10. Storage, reports, and export use Gregorian dates in the user's time zone (`Calendar.gregorian(in:)`).

### W3. `.claude/skills/data-migration/SKILL.md` (new)

Front matter with a `description` that triggers on "add a field", "change saved data", "bump schema", "migration".

Two recipes:

- **Add a field** (no schema bump): default in `DecodingDefaults`, decode test with old JSON that lacks the field, encode/decode round trip, unknown raw value test.
- **Bump the schema**: new `schemaVersion`, a migrator from the old shape, a fixture of the old file under `Tests/` (check where fixtures live now), a re-run test that proves no data loss and no overwrite of newer data, a corrupt-file test.

Both recipes end with the Definition of done checks.

### W4. `.claude/agents/ui-verifier.md` (new) and `docs/design/`

- `docs/design/`: the main session renders the 6 artboards (Settings, Reports, Menu bar, Water bubble, Reading corner popup, Meditation) to PNG, one file each, plus `docs/design/README.md` that names each file, its canvas URL, and the render date.
- Agent front matter: `tools: Read, Grep, Glob, Bash`. Read-only for `Sources/` and `Tests/`. It writes screenshots only to a scratch folder it names in the report.
- Steps: check that Sathi runs (`pgrep -x Sathi`; never install it), ask the brief for which windows to check, take each window with `screencapture -l <windowID>` (find the window ID with a short `swift` or `osascript` command that the agent file gives in full), read the PNG and the matching `docs/design/` PNG, compare: colors against the `Night` tokens, text strings, layout order, sizes from `UIMetrics`.
- Report: one table per window: element, design, app, severity (BLOCKER, MAJOR, MINOR). Never edit files.
- The agent states its limits: it cannot open a reminder that is not due; the brief must say how to make it show (for example, the debug menu or a short interval in Settings) or skip it.

### W5. `test-writer.md` and `.claude/skills/write-unit-tests/SKILL.md` (update)

Add, with one short code example each taken from a real test in the repo:

1. File tests in a temp folder (`TestFiles`), with `flush()` before reading the file back.
2. Permission failure tests: `chmod` the folder, `defer` restore, assert no overwrite and a retry.
3. `InMemoryHistoryStore` for history-based logic; `SpyFileExporter` for export.
4. `FixedZone` calendars for date logic; never the system time zone.
5. Proving red in a scratch copy: how the test-writer proves its tests fail on assertions while the API is missing (copy the repo to the scratchpad, add stubs there, run the suite). Add this to `test-writer.md` Steps.

Keep `write-unit-tests/SKILL.md` ≤ 200 lines.

### W6. `scripts/perf.sh` and `perf-auditor.md` (update)

`perf.sh`:

- Default run unchanged (idle budget: 40 MB, 1% CPU, 10 wakeups/min).
- New flag `--windows`:
  1. Measure footprint (baseline). Print it.
  2. Prompt: "Open Reports and Settings, close both, then press Enter." Wait `SETTLE_SECONDS` (default 5). Measure (cycle 1).
  3. Same prompt again. Measure (cycle 2).
  4. Print a table: baseline, cycle 1, cycle 2, growth (cycle 2 − cycle 1).
  5. Fail when cycle 1 or cycle 2 ≥ `MAX_WINDOW_FOOTPRINT_MB` (default 50), or growth ≥ `MAX_LEAK_MB` (default 3).
- Every limit is an env var with a default at the top, like the others. Move the footprint reading into a function so both modes use it.
- `bash -n` passes; `shellcheck` passes if it is installed.

`perf-auditor.md`: add a step for `./scripts/perf.sh --windows` when the brief mentions windows or memory, and explain the expected one-time ~23 MB first-window cost.

Also update `.claude/rules/performance.md` and `.claude/skills/perf-check/SKILL.md` to name the `--windows` mode and the < 50 MB after-window budget, if they do not already.

## Proof that defines done

1. **Dry run of `/add-habit stretch`.** A fresh agent that did not write W1 reads only the new skill and the code. It lists every file it would change. It changes nothing. The main session compares the list with the `switch` sites above and with the result of a scratch build that adds `case stretch` to `HabitID` (in a scratch copy, never in the repo). Every compiler error file must be in the skill's list or covered by a step.
2. **Every path and name in W1–W6 exists.** A script extracts every backticked path and checks it with `test -e`; the reviewer checks type names with `grep`.
3. `bash -n scripts/perf.sh`; `./scripts/perf.sh` with Sathi stopped exits 2.
4. `./scripts/test.sh` and `./scripts/lint.sh` still pass (no Swift change expected).
5. `code-reviewer` finds no BLOCKER.
