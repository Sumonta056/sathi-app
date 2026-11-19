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
Spec 5g2: `docs/specs/phase-5g2-palette.md`

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

## Phase 8: Gym (Shokti)

Spec: `docs/specs/gym-shokti-design.md`

- [x] Rules in `.claude/rules/business-logic.md`
- [x] Gym core: `HabitID.gym`, `GymPrefs`, `GymRules`
- [x] Gym UI: Shokti buddy, invite, session, settings tab, menu card
- [x] Reports and README
- [ ] Website text and screenshots (`/sathi-website`)
- [ ] `perf.sh --windows` run by the user in Terminal, and the visual check with `ui-verifier`

## Phase 9: Days off

Rules: `.claude/rules/business-logic.md`

- [x] Rules in `.claude/rules/business-logic.md`
- [x] `DayKey`, `HabitDays`, and weekdays plus days off in every buddy's prefs
- [x] Reminders skip days off
- [x] Engine: today off closes that buddy's reminder; "Day off" pill
- [x] Streaks and reports skip days off
- [x] Settings: weekday row and days-off card for every buddy
- [x] Menu pill and report calendar style
- [ ] Docs, Definition of done, website

## Phase 12: Quick reminder

Spec: `docs/specs/phase-12-quick-reminder.md`

- [x] Spec, business rules, branch
- [x] Core models, time math, decoding
- [x] Copy
- [x] Engine actions, show loop, snooze, port
- [x] Levels and the shared lock
- [x] Menu card and add form
- [x] Popup, snoozed note, lock, presenter
- [x] Settings card
- [ ] Definition of done
- Open: perf.sh, perf.sh --windows, hand test, ui-verifier, website.

## Phase 15: Breathing redesign

Spec: `docs/specs/phase-15-breathing.md`

- [x] Rules and words in `.claude/rules/business-logic.md`
- [x] Pausable `Session`, saved `meditationSession`, restore, midnight end
- [x] Calm 4·6 default pattern and breath copy
- [x] `SessionAudio` port, `BreathCues`, Engine cues
- [x] SPM resources, safe locator
- [x] Breath audio player, voice, music fade
- [x] Settings Sound card
- [x] Days-off month calendar picker
- [x] Figtree font with fallback
- [x] Breathing card: orb, ring, time left, pause
- [x] Docs
- Open: perf.sh, perf.sh --windows, ui-verifier, website.

## Phase 17: Daily activity tracker

Spec: `docs/specs/phase-17-activity-tracker.md`
Plan: `docs/specs/phase-17-plan.md` (4 waves, 9 parallel tracks, worktrees, merge rules)
Test notes: `docs/specs/phase-17-test-notes.md`
Progress and start-here: `PROGRESS.md`
ADR: `docs/adr/0001-activity-tracker-replaces-time-blocks.md`

- [x] Design, glossary, spec, plan, goals, test notes
- [x] Wave 0: contracts
- [x] Wave 1: T1 Engine flow · T2 Storage · T3 Mac platform · T4 Prompt views · T5 Reports and end of day · T6 Settings and menu views (parallel)
- [x] Wave 2: C Calendar engine · I Integration (parallel)
- [x] Wave 3: finish, review, fixes, docs, website
- [ ] User: perf (`perf.sh`, `--windows`), hand tests, merge to `main`, push
- Later: Week view, remove time blocks.

## Phase 18: Main window, quick panel, one activity prompt, ranges

Spec: `docs/specs/phase-18-app-window.md`
Plan: `docs/superpowers/plans/phase-18-app-window.md` (16 tasks)
Design: `docs/design/phase-18/` (Main, Activities, Reports, Settings, QuickPanel, ActivityPrompt)
Branch: `feat/app-window` (worktree `../Sathi-app-window`)

- [x] Spec, plan, glossary words, design mockups
- [ ] 1 Rules and words first
- [ ] 2 `StatsRange` and the compare words
- [ ] 3 Buddy totals for a range
- [ ] 4 Activity stats, text, and CSV export for a range
- [ ] 5 `MainPage` and one presenter call
- [ ] 6 Today screen model and `TodayModel`
- [ ] 7 Activity prompt model and engine changes
- [ ] 8 Activity prompt view
- [ ] 9 One centered prompt panel; notes and end of day at center
- [ ] 10 Main window shell, Dock icon, launch and close
- [ ] 11 Settings pages in the main window
- [ ] 12 Today page
- [ ] 13 Reports page with ranges
- [ ] 14 Activities page with ranges
- [ ] 15 Quick panel
- [ ] 16 Docs, website shots, Definition of done
- Open questions (defaults in the spec): Q1 time blocks in the quick panel, Q2 "Add a buddy" page, Q3 login-item detection, Q4 Keep going minutes.

## Phase 21: Calendar page and manual merge

Spec: `docs/specs/phase-21-calendar-page.md`
Plan: `docs/superpowers/plans/phase-21-calendar-page.md` (Track 1 C1–C10, Track 2 M1–M5, integration I1–I2)
Branch: `feat/calendar-page` (worktree `.worktrees/calendar`)

- [x] Rules and words (business-logic "Calendar page", Activity tracker rule 11f)
- [x] Track 1: Calendar page (experimental, off by default): switch, Day / Week / Month on a 6 AM to 6 AM grid, no duplicates, display join, shown calendars, sync on `EKEventStoreChanged` with no timer, create / edit / delete events, tracker agreement (C7), statistics
- [x] Track 2: manual merge on the Activities page Day view: check, calendar update then delete, rollback, undo
- [x] I1: Merge on the Calendar page Day view (⌘-click)
- [x] I2: cross-track acceptance tests, deferred fixes (page resets, refused-save line, memory release on close, locked time-block event), docs, checks
- [ ] User: hand tests (real `EKEventStoreChanged`, `ical://ekevent` link, merge with real calendar events), `perf.sh --windows`, merge to `main`, push
- [ ] Website (later; the page is experimental)

## Phase 22: Main window fit and activity prompt fix

Spec: `docs/specs/phase-22-window-fit.md`
Branch: `feat/window-fit` (worktree `../Sathi-window-fit`), tracks `feat/wf-prompt`, `feat/wf-window`, `feat/wf-narrow`

- [x] Rules and words (business-logic Activity tracker rule 3, GLOSSARY Narrow and Wide layout)
- [x] Track A: activity prompt 1040×720 for every reason, no scroll, paired rows, native drag, drop onto the display with the larger part
- [x] Track B: Main window fills the pointer display's visible frame, min 640×520, drag strip, fit on display change keeps its shape
- [x] Track C: narrow layout below 900 px (rail, Today, Activities drawer below 1100, Calendar, Reports, Settings rows)
- [x] Merge, checks (tests, lint, release build), real prompt check (1040×720, no scroll)
- [ ] User: `perf.sh`, `perf.sh --windows`, hand tests (strip drag and zoom across displays, tile then move, prompt drag across displays)
- [ ] Website

## Phase 23: To-dos (Apple Reminders)

Spec: `docs/specs/phase-23-todos.md`. Branch: `feat/todos` (worktree `../Sathi-todos`).

- [x] Grill, design (option A), plan approved, business rules
- [x] Track A: Core models, `TodoStore` port, prefs, fake
- [x] Track B: To-dos page, Settings, EventKit store, Info.plist
- [x] Track C: Quick panel card, To-do due prompt, day summary
- [x] Track D: to-dos on the Calendar page
- [x] Rebased on Phase 22 `main`; tracks joined; checks (tests, lint, release build)
- [ ] User: install, hand tests, perf, `--windows`, merge to `main`, website

## Phase 24: Calendar Week redesign (H2) and event pop-up fix

Spec: `docs/specs/phase-24-calendar-h2.md`. Design: board H2 on https://claude.ai/artifact/MqDQoohF24VV4m9bKQzhX9
Branches: Track A `fix/event-ask-held`, Track B `feat/calendar-week-h2` (worktree `../Sathi-cal-h2`)

- [ ] Track A: event pop-up fix. Rules (Activity tracker rules 2 and 7, To-dos rule 11); an event ask shows at its start on top of other pop-ups (held pop-up comes back) and during a pause, a time block, or a buddy session; only Away and a lock make it wait, then it asks while the event is still on; "Log and tell" asks when busy
- [x] B0: rules (Calendar page rules 5, 5a, 5b, 12, 14, 15) and this entry
- [ ] B1: joined activities keep their category color, with a link icon
- [ ] B2: Core layout: host and child, side by side (< 30 min, 2 lanes, "+N"), raised depth max 2, minimum-height nudge
- [ ] B3: event card and activity block views, sizes (60 pt hour), Away stripes only in Week
- [ ] B4: to-do pill and dashed due line
- [ ] B5: hover card, `CalendarHoverInfo`, "Start as activity" (`startActivity(fromEvent:)`)
- [ ] B6: Week side panel hidden by default (`sidePanelShownWeek`, `/data-migration`)
- [ ] B7: Day view uses the same layout, cards, pills, and hover card
- [ ] Checks (tests, lint, release build), `perf.sh`, `ui-verifier` against H2, code review, `CLAUDE.md` module map and README
- [ ] User: hand tests, `perf.sh --windows`, merge to `main`, push
- [ ] Website screenshots (later, `/sathi-website`)

## Phase 25: Calendar Day and Week, Plan | Actual

Spec: `docs/specs/phase-25-calendar-plan-actual.md`. Design: https://claude.ai/artifact/QpmNuNugfzU3GCvNQRG79d
Branch: `feat/calendar-plan-actual` (worktree `../Sathi-plan-actual`), one branch and worktree per track.

- [x] Rules (Calendar page rules 5, 5a, 5b, 11, 12, 14, 15) and this entry
- [x] B5: to-dos in the split: option A, pill on a dashed due line in the Plan half (https://claude.ai/artifact/5qcmvor46ZBi7F6sQ2B3ub)
- [ ] T1 (B1): Core layout (halves, lanes, raised, push, row growth, night fold, done during, rounded once)
- [ ] T2 (B3 data): `calendarPage.weekDays` pref (3, 4, 5, 7) and range math (`/data-migration`)
- [ ] T3 (B2): Day view cards, link gutter, header
- [ ] T4 (B3 UI): Week view, day count control, narrow mode, night fold strip
- [ ] T5 (B4): hover card and actions, no Merge on the Calendar page
- [ ] Remove the replaced layout (host nesting, option A grouping, trim, narrow-lane chip, old nudge) and its tests
- [ ] Checks (tests, lint, release build), `perf.sh`, `ui-verifier` against the mockup, code review, `CLAUDE.md` module map and README
- [ ] User: hand tests, `perf.sh --windows`, merge to `main`, push
- [ ] Website screenshots (later, `/sathi-website`)

## Later

- Days off: a lock or Nudgy bubble that shows at 23:58 stays after midnight into a day off (only a settings change closes it, rule 11). Close it at the first tick of a new day if users notice
- 6b: `RawJSON` stores numbers as `Double`; integers above 2^53 and `-0.0` are not written back exactly
- 6b: a written month file lists known events first, then unknown events (not sorted by date; Sathi sorts on read)
- 6b: each month file is decoded twice and each event encoded once more (about 3–4 ms for a few hundred events)
- Phase 6: `schemaVersion` is written but never read. The first schema bump must add a version check in `JSONFiles.load`
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
| 2026-10-27 | Every buddy may use Gentle, Nudgy, or Strict, and each keeps its own level. At Strict any buddy locks after 2 snoozes. This replaces "Reading and Meditation never lock" and "A stored Strict … acts as Nudgy". Each buddy has a "Show a close button" switch, on by default; a close is a normal snooze. |
| 2026-10-24 | Phase 5: commit approval per group (5a–5c, 5d–5f, 5g–5h); full review only for 5e and 5g, one shared review for view slices. |
| 2026-10-25 | 5b: reading weekdays (all on by default) and `reminderStyle` (corner default) added to Core. Water interval chips 30/60/90/120. "Quiet in meetings" shows a disabled "Soon" switch. |
| 2026-10-25 | 5c: header streak = best current streak of enabled habits. "Rest of day" pause ends at midnight. |
| 2026-10-25 | Review 5a–5c: a settings change that moves a due time into the future cancels the queued or snoozed reminder. "Rest of day" skips slots missed during the pause. "Focus screen" can be picked now; 5e wires it (5a–5c are not released before 5e). |
| 2026-10-25 | 5g: calendar and facts follow the selected tile; off habits show a dimmed "Off" tile; PDF in 5g and names the habit; a cancel keeps the old export note; save panel is a sheet; old `Palette` removal moves to slice 5g2. |
| 2026-10-25 | 5h: the Reports Export menu is removed (save panel wakeups). Memory budget: < 40 MB fresh idle, < 50 MB after a window. Swift Charts stays. |
| 2026-10-25 | Fix: on macOS 27 every reminder panel was 0×0 (`NSHostingView.fittingSize` after `sizingOptions = []`), so no reminder was visible. Buddies are now independent: each has its own reminder, snooze, ignore timer, and session; no queue. Corner panels stack top-right on the display with the mouse. |
| 2026-11-09 | Daily activity tracker (phase 17): separate from time blocks first, replaces them later (ADR 0001). Off by default. Prompts never go away by themselves. Scheduled prompts sit in the corner and never take the keyboard; the center panel opens only from the shortcut, the menu, or after Away. Raw activities are saved per month; reports are built on demand. |
| 2026-11-11 | Phase 18: one main window (Today, Activities, Reports, Settings) replaces the Settings and Reports windows; Dock icon only while it is open; the menu panel becomes a short quick panel; the 5 tracker prompts become 1 activity prompt at the screen center that takes the keyboard only when the user opened it; Reports and Activities get Day / Week / Month ranges with compare. Buddy reminders do not change. No saved-data change. |
| 2026-10-24 | Phase 1 fix: a schedule change just after midnight counts the new day, not yesterday. |
| 2026-11-15 | Phase 22: the Main window opens filling the visible frame of the pointer display and relies on macOS tiling (no own snap); pages use a narrow layout below 900 px wide. The activity prompt has one size, 1040×720, with no scroll, and a native drag. No saved-data change. |
| 2026-11-18 | Phase 24: calendar events come first; an event ask shows on top of other tracker pop-ups and during busy states, and only Away and a lock make it wait. The Calendar Week side panel has its own saved choice (`sidePanelShownWeek`, default hidden). The hour height is 60 pt in all views. |
| 2026-11-19 | Phase 26: Today and Reports become 1 Dashboard page with one Day / Week / Month switch; sidebar Dashboard, Activities, PLAN (To-dos, Calendar). No saved-data change. |
