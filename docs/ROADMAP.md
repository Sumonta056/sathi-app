# Sathi roadmap

Branch: `feature/redesign-v2`. Design: https://claude.ai/artifact/AgF243uMtC5H8ySBfdXx6e

Use the `/roadmap` skill to see the next step and to update this file. Each phase runs the `/feature` loop and ends with one commit. Tick a box only when its tests pass.

Status: `[ ]` to do, `[~]` in progress, `[x]` done.

## Phase 0: Structure

- [x] `.claude/rules/business-logic.md`
- [x] `docs/ROADMAP.md`
- [x] `/roadmap` skill

## Phase 1: Habit-agnostic core (no behavior change)

- [x] `Engine.habits: [HabitID: HabitState]` replaces `water` and `reading`
- [x] Exhaustive `switch` on `HabitID` everywhere
- [x] `HabitRules` protocol, `WaterRules`, `ReadingRules` in `SathiCore/Habits/`
- [x] `Scheduler` folded into the rules, `SchedulerTests` moved to `WaterRulesTests` and `ReadingRulesTests`
- [x] All old tests pass

## Phase 2: File storage

Spec: `docs/specs/phase-2-storage.md`


- [x] `Prefs` split into `GeneralPrefs`, `WaterPrefs`, `ReadingPrefs` (needs the migration)
- [x] `HistoryEvent` (done, snooze, skip)
- [x] `HistoryStore` port and `InMemoryHistoryStore` fake
- [x] `FileStateStore`, `FileHistoryStore` (atomic, `schemaVersion`)
- [x] `LegacyMigrator` from `sathi.state.v1`, with fixture test
- [x] Coalesced saves (`Timing.saveCoalesce`)
- [x] Hardening H1–H7 from review (H6: times stored to the whole second; H7: a re-run never overwrites newer state): migration marker, idempotent migration, no overwrite on unreadable files, retry failed writes

## Phase 3: Meditation (Shanti), core

- [ ] `HabitID.meditation`, `MeditationPrefs`, `MeditationRules`
- [ ] `BreathingPattern` (box, relax, even)
- [ ] `Phase.session(HabitID)`
- [ ] Copy for Shanti

## Phase 4: Reports and export, core

- [ ] `ReportBuilder` (day, week, month)
- [ ] `StreakCalculator` across month files (removes the 3-month streak cap from Phase 2)
- [ ] `CSVExporter`, `JSONExporter`, `FileExporter` port

## Phase 5: UI redesign

- [ ] Theme: night-sprout `Palette`, SF Rounded `Typography`
- [ ] Settings window: sidebar, General, Water, Reading, Meditation, Add a buddy (coming soon)
- [ ] Menu bar popover with rings and pause chips
- [ ] Water bubble (dark)
- [ ] Reading corner popup and timer pill
- [ ] Meditation breathe view
- [ ] Reports window with charts, streak calendar, export menu
- [ ] `/perf-check` passes

## Phase 6: Claude setup

- [ ] Rewrite `add-habit` skill for modules
- [ ] `.claude/rules/storage.md`
- [ ] `data-migration` skill
- [ ] `ui-verifier` agent
- [ ] Update `test-writer`, `write-unit-tests`, `perf-auditor`, `scripts/perf.sh`

## Phase 7: Docs and release check

- [ ] Update `README.md` and `CLAUDE.md`
- [ ] Definition of done in `CLAUDE.md` passes

## Later

- Enforce whole-second times in the types: `HistoryEvent.date` setter private, `LiveState` time writes through cutting setters
- Migration re-run after a failed first history write: merge v1 `streakReset` into an existing `state.json` instead of skipping it

- Timestamped `.corrupt` names, so a second quarantine keeps the first copy

- Morning dew (light) theme and Follow macOS
- Real Stretch, Eye break, Walk, Posture modules

## Decisions

| Date | Decision |
|---|---|
| 2026-10-24 | Storage: monthly JSON files in Application Support. History kept forever. |
| 2026-10-24 | Font: SF Rounded. No bundled font. |
| 2026-10-24 | Theme: Night only first. |
| 2026-10-24 | "Add a buddy" shows coming-soon cards. |
| 2026-10-24 | `HabitID` stays an enum. Each habit's logic lives in a `HabitRules` module. |
| 2026-10-24 | Reading and Meditation never lock the screen. |
| 2026-10-24 | RAM keeps the last 3 months of events, so streaks and week views work across a month boundary. |
| 2026-10-24 | Each phase runs through subagents: test-writer, implementer, code-reviewer. |
| 2026-10-24 | Phase 1 fix: a schedule change just after midnight counts the new day, not yesterday. |
