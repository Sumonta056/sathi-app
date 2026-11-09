# Progress: Phase 17, Daily activity tracker

Give this file to a new session first. It says where the work is and what to read next.

## Start here (new session)

1. Read `CLAUDE.md` (project rules, commands, Definition of done).
2. Read this file to the end.
3. Read `docs/specs/phase-17-plan.md` and find the first subplan that is not done.
4. Read only the spec rules and goals that subplan lists, in `docs/specs/phase-17-activity-tracker.md`.
5. Check out the branch `feat/activity-tracker`. Run `./scripts/test.sh` to confirm a green start.
6. Run the `/feature` loop for that subplan: plan → user approval → failing tests → code → checks → review against the goal IDs → 1 commit.
7. Update this file: tick the subplan, add a session log row with the commit hash, and write the next step.

## Documents

| What | Where |
|---|---|
| Spec: 64 rules, storage, ports, 70 goals | `docs/specs/phase-17-activity-tracker.md` |
| Plan: 5 subplans, their goals, exit checks, commit messages | `docs/specs/phase-17-plan.md` |
| Manual test notes per subplan | `docs/specs/phase-17-test-notes.md` |
| Why the tracker replaces time blocks later | `docs/adr/0001-activity-tracker-replaces-time-blocks.md` |
| Words (Activity, Away, Switch time, …) | `GLOSSARY.md` |
| Short business rules | `.claude/rules/business-logic.md`, section "Activity tracker" |
| Roadmap entry | `docs/ROADMAP.md`, Phase 17 |
| Design: Demo, Flow, Goals, Decisions, Plan, Test notes, screens | https://claude.ai/artifact/YHqbbEbFiGvqgdGVHSzMjU |

## Status

Branch: `feat/activity-tracker` (from local `main`). Nothing is pushed.

- [x] Design and docs (grill session, 50 questions, 2026-11-09)
- [ ] Subplan 1: Core and engine (17a, 17b, 17k engine part): 24 goals
- [ ] Subplan 2: Mac and prompts (17c, 17d, 17l): 16 goals
- [ ] Subplan 3: Calendar (17e, 17j): 14 goals
- [ ] Subplan 4: Reports and end of day (17f, 17g): 11 goals
- [ ] Subplan 5: Settings, menu, and release (17h, 17i): 5 goals

## Next step

Subplan 1, slice 17a: show the user the 17a plan (files, types, tests) before any code.

## Key decisions (full list in the design page, Decisions tab)

- Separate from time blocks now. Replaces them in a later phase (ADR 0001).
- Off by default. It asks only inside tracker hours and on tracker days. It does not ask on days off, during a break, while a time block or a buddy session runs, during quiet time, or while a full-screen lock shows.
- Prompts: A (corner, What now?), C (corner, Still on it?), B (center, ⌥⌘Space or menu), D (center, after Away), F (corner note, calendar event). None closes by itself, except note F after 1 min.
- Sathi never adds time that the user did not confirm. Done opens A with the Started row (switch time).
- Away = lock, sleep, lid, idle 30 min, or a break.
- Calendar write: a check box on each activity. Calendar read: opt-in, ticked calendars only. The category of a calendar is its name by default.
- Buddy sessions log their own activity. When a session ends, A asks "Continue {last activity}?".
- Quiet time ("No popups until it ends") holds back tracker and buddy popups. Quick reminders still show.
- Data: raw activities in `activities/YYYY-MM.json`, kept forever. Reports are built on demand.

## Rules that bite (from CLAUDE.md)

- No code comments. Max 200 lines per file. No magic numbers (use `Timing`, `Limits`, `UIMetrics`).
- SathiCore never imports AppKit or SwiftUI. The Engine reads time only from `clock.now`.
- No repeating timers. Every wait goes through `upcomingDeadlines()`.
- Tests first, with `EngineHarness` and fakes. No real waits.
- Saved data changes follow `.claude/rules/storage.md` and `/data-migration`.
- Commit on the branch at the end of each subplan. Ask before any push or merge to `main`.
- `Feature.md` is the user's own notes. Never commit or delete it.
- `/perf-check` installs the release build and runs it on the user's real data. Ask the user first.

## Session log

| Date | Session | Done | Commit |
|---|---|---|---|
| 2026-11-09 | Design (local) | Grill, design page, spec, plan, goals, test notes, this file. This file replaces the old Sathi 2.0 handover (in git history before `5dfff66`). | `5dfff66` + this file |

## Open items

- None in the design. Add problems found during coding here.
