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

Spec: `docs/specs/phase-3-meditation.md`


- [x] `HabitID.meditation`, `MeditationPrefs`, `MeditationRules`
- [x] `BreathingPattern` (box, relax, even)
- [x] `Phase.session(HabitID)`
- [x] Copy for Shanti
- [x] Review fixes F1–F7 and round 2 (restart keeps the stop rule, a stale snooze is dropped on re-enable)

## Phase 4: Reports and export, core

Spec: `docs/specs/phase-4-reports.md`


- [x] `ReportBuilder` (day, week, month)
- [x] `StreakCalculator` across month files (removes the 3-month streak cap from Phase 2)
- [x] `CSVExporter`, `JSONExporter`, `FileExporter` port
- [x] Review fixes R1–R5 (midnight-DST days, streak windows, Gregorian dates, streak cache, one clock)

## Phase 5: UI redesign

Spec 5a: `docs/specs/phase-5a-theme.md`
Spec 5b: `docs/specs/phase-5b-settings.md`
Spec 5c: `docs/specs/phase-5c-menubar.md`
Spec 5d: `docs/specs/phase-5d-water-bubble.md`
Spec 5e: `docs/specs/phase-5e-reading-corner.md`
Spec 5f: `docs/specs/phase-5f-meditation.md`
Spec 5g: `docs/specs/phase-5g-reports.md`
Review fixes 5g: `docs/specs/phase-5g-review-fixes.md`
Spec 5g2: `docs/specs/phase-5g2-palette.md`
Review fixes 5d/5f: `docs/specs/phase-5df-review-fixes.md`
Review fixes 5a–5c: `docs/specs/phase-5abc-review-fixes.md` (done)

- [x] Theme: night-sprout `Night` palette, SF Rounded `Typography`, shared components
- [x] Settings window: sidebar, General, Water, Reading, Meditation, Add a buddy (coming soon)
- [x] Menu bar popover with rings and pause chips
- [x] Water bubble (dark)
- [x] Reading corner popup and timer pill
- [x] Meditation breathe view
- [x] Reports window with charts, streak calendar, export menu
- [x] 5g2: Lock screen and legacy reading-focus views on `Night`; delete the old `Palette`
- [x] `/perf-check` passes (budget updated: < 50 MB after a window; Export menu removed)

## Phase 6: Claude setup

Spec: `docs/specs/phase-6-claude-setup.md`

- [x] Rewrite `add-habit` skill for modules
- [x] `.claude/rules/storage.md`
- [x] `data-migration` skill
- [x] `ui-verifier` agent
- [x] Update `test-writer`, `write-unit-tests`, `perf-auditor`, `scripts/perf.sh`

Spec 6b: `docs/specs/phase-6b-tolerant-decoding.md`

- [x] 6b: unknown enum values fall back to defaults; unknown history events and unknown event fields are kept and written back

## Phase 7: Docs and release check

- [x] Update `README.md` and `CLAUDE.md`
- [x] Definition of done in `CLAUDE.md` passes (tests, lint, release build, install, idle perf 0.0% / 18 MB / 0 wakeups; version 2.0, `Sathi-2.0.dmg`)
- [ ] `perf.sh --windows` run by the user in Terminal (not run yet)

## Later

- 6b: `RawJSON` stores numbers as `Double`; integers above 2^53 and `-0.0` are not written back exactly
- 6b: a written month file lists known events first, then unknown events (not sorted by date; Sathi sorts on read)
- 6b: each month file is decoded twice and each event encoded once more (about 3–4 ms for a few hundred events)
- Phase 6: `schemaVersion` is written but never read. The first schema bump must add a version check in `JSONFiles.load`
- 5f: breathing sessions end mid-cycle; the last ~12 s repeat the last round (user: accept for now)
- 5f: `BreatheView` reads the breathing style live; a style change mid-session jumps the phase (store it at session start)
- 5d: `goalText(.water)` uses `Int(dailyGoalGlasses)`; a fractional goal reads "of 7" next to 8 drops
- 5e review: `EngineHarness` takes no calendar, so `Engine.comesBackText` time-zone use is not proven by a test
- 5e review: a reading style change during the 4.5 s celebration can put the legacy card in a corner panel (store the style in `Celebration`)
- 5e review: `snooze()` reads `usesCorner` at snooze time, not at show time (style changed while the invite is open → no note)
- 5e review: `UIController` stored panels are `internal` so its extensions can use them
- 5h: measure the 5d/5e SwiftUI animations (water bob, spark, 5-min `IgnoreBar` scale) on the installed build; SwiftUI may drive them per frame on the main thread
- Streak memory/history split assumes the clock never goes back across a month after launch (store the oldest loaded window)
- `windowStart` uses the system calendar; use the Gregorian calendar to match storage
- Menu subtitle uses the published `now` while the streak uses `clock.now` (cosmetic, one minute after midnight)

- `percentOfGoal` rounds 99.5 up to 100 (product choice)
- 5h: bring export back without the `NSSavePanel` wakeup cost (for example, save to ~/Downloads and show the file in Finder); PDF renderer was removed with the menu
- 5h: memory stays ~23 MB higher after the first SwiftUI window (helper process is the only fix)
- 5g: a stored selection of an off habit comes back when the habit is turned on again
- 5h: check 6-row months (March 2026) plus 3 facts in the 250-pt calendar card, and bar width without the 34-pt cap

- A settings change during a pause moves a missed clock slot to the next slot (rule 5). Confirm with the user or add a test
- Independent buddies: two centered panels (focus reading session, breathing session, centered celebration) sit on top of each other
- Independent buddies: animations keep running in panels hidden behind the water lock; pause on window occlusion, then run perf with 3 reminders and a session open
- Independent buddies: the corner stack has no lower bound on short screens (clamp or add a second column)
- `BreathingPattern.step` crashes on an infinite elapsed time (no app path reaches it)

- Enforce whole-second times in the types: `HistoryEvent.date` setter private, `LiveState` time writes through cutting setters
- Migration re-run after a failed first history write: merge v1 `streakReset` into an existing `state.json` instead of skipping it

- Timestamped `.corrupt` names, so a second quarantine keeps the first copy

- Morning dew (light) theme and Follow macOS
- Real Stretch, Eye break, Walk, Posture modules
- `BuddySwitch` reads as a "selected button" in VoiceOver; `accessibilityRepresentation { Toggle }` breaks ViewInspector lookups (needs a test helper change)
- "Stay quiet in meetings": pause while camera, mic, or a full-screen app is on (needs a new Core port)

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
| 2026-10-24 | Meditation is off by default, so an update never starts a reminder the user did not ask for. |
| 2026-10-24 | A stored Strict on Reading or Meditation acts as Nudgy. Only Water can lock. |
| 2026-10-24 | Phase 5: new `Night` palette next to the old `Palette`; each slice moves its screen; 5g deletes the old one. |
| 2026-10-24 | `faint` is #7784A0 (canvas #6F7C97 fails 4.5:1). Never on a card. |
| 2026-10-24 | Phase 5: commit approval per group (5a–5c, 5d–5f, 5g–5h); full review only for 5e and 5g, one shared review for view slices. |
| 2026-10-25 | 5b: reading weekdays (all on by default) and `reminderStyle` (corner default) added to Core. Water interval chips 30/60/90/120. "Quiet in meetings" shows a disabled "Soon" switch. |
| 2026-10-25 | 5c: header streak = best current streak of enabled habits. "Rest of day" pause ends at midnight. |
| 2026-10-25 | Review 5a–5c: a settings change that moves a due time into the future cancels the queued or snoozed reminder. "Rest of day" skips slots missed during the pause. "Focus screen" can be picked now; 5e wires it (5a–5c are not released before 5e). |
| 2026-10-25 | 5g: calendar and facts follow the selected tile; off habits show a dimmed "Off" tile; PDF in 5g and names the habit; a cancel keeps the old export note; save panel is a sheet; old `Palette` removal moves to slice 5g2. |
| 2026-10-25 | 5h: the Reports Export menu is removed (save panel wakeups). Memory budget: < 40 MB fresh idle, < 50 MB after a window. Swift Charts stays. |
| 2026-10-25 | Fix: on macOS 27 every reminder panel was 0×0 (`NSHostingView.fittingSize` after `sizingOptions = []`), so no reminder was visible. Buddies are now independent: each has its own reminder, snooze, ignore timer, and session; no queue. Corner panels stack top-right on the display with the mouse. |
| 2026-10-24 | Phase 1 fix: a schedule change just after midnight counts the new day, not yesterday. |
