# Progress: Phase 17, Daily activity tracker

Give this file to a new session first. It says where the work is and what to read next.

## Start here (new session)

The user gives a short prompt that names a role: **wave 0**, a **track** (T1–T6, C, I), **merge**, or **wave 3**. Then:

1. Read `CLAUDE.md` (project rules, commands, Definition of done).
2. Read this file to the end.
3. Read `docs/specs/phase-17-plan.md`: the section "Merge conflict rules" and the section of your role. Read nothing else of the plan.
4. Read only the spec rules and goals that your section names, in `docs/specs/phase-17-activity-tracker.md`.
5. A track: make your worktree and branch as your section says, then read your track file `docs/tracker-progress/<track>.md`. Resume from it if it has progress.
6. Work test-first (`/feature` loop). Write your plan into your track file first. You may go on without waiting for the user, because the design is approved. Stop and ask only for a merge to `main`, a push, a merge conflict, or a contract defect.
7. Edit only the files your section owns (rule 2). Update only your own track file, never this file (rule 6).
8. When done (rule 7): 1 commit on your branch, set your track file status to "done, ready to merge", and report the goal IDs met.

**Merge role:** merge every track whose file says "ready to merge", in the order of rule 8, run the tests after each, then update the Status table below and add a session log row.

## Roles and short prompts

| Role | Prompt to give |
|---|---|
| Wave 0 | `Read PROGRESS.md. Do wave 0.` |
| A wave 1 track | `Read PROGRESS.md. Do track T1.` (or T2 … T6) |
| A wave 2 track | `Read PROGRESS.md. Do track C.` (or I) |
| Merge | `Read PROGRESS.md. Merge the ready tracks.` |
| Wave 3 | `Read PROGRESS.md. Do wave 3.` |
| All in this local session, with subagents | `Read PROGRESS.md. Run the next wave with parallel subagents in worktrees, then merge.` |

## Documents

| What | Where |
|---|---|
| Spec: 64 rules, storage, ports, 70 goals | `docs/specs/phase-17-activity-tracker.md` |
| Plan: 4 waves, 9 tracks, file ownership, merge conflict rules, goals per track | `docs/specs/phase-17-plan.md` |
| Status of each track (written by that track only) | `docs/tracker-progress/<track>.md` (wave 0 creates them) |
| Manual test notes per wave | `docs/specs/phase-17-test-notes.md` |
| Why the tracker replaces time blocks later | `docs/adr/0001-activity-tracker-replaces-time-blocks.md` |
| Words (Activity, Away, Switch time, …) | `GLOSSARY.md` |
| Short business rules | `.claude/rules/business-logic.md`, section "Activity tracker" |
| Roadmap entry | `docs/ROADMAP.md`, Phase 17 |
| Design: Demo, Flow, Goals, Decisions, Plan, Test notes, screens | https://claude.ai/artifact/YHqbbEbFiGvqgdGVHSzMjU |

## Status

Base branch: `feat/activity-tracker` (local; not pushed). Track branches and worktrees: see the plan.

| Wave | Track | Branch | Status |
|---|---|---|---|
| — | Design and docs | `feat/activity-tracker` | done |
| 0 | Contracts | `feat/activity-tracker` | done (`2381f1f`) |
| 1 | T1 Engine flow | `feat/tracker-t1-engine` | done, merged (`11a0f49`) |
| 1 | T2 Storage | `feat/tracker-t2-storage` | done, merged (`d6c9170`) |
| 1 | T3 Mac platform | `feat/tracker-t3-platform` | done, merged (`37656b3`) |
| 1 | T4 Prompt views | `feat/tracker-t4-prompts` | done, merged (`0349591`) |
| 1 | T5 Reports and end of day | `feat/tracker-t5-reports` | done, merged (`80f11fa`) |
| 1 | T6 Settings and menu views | `feat/tracker-t6-settings` | done, merged (`7e6513d`) |
| 2 | C Calendar engine | `feat/tracker-c-calendar` | done, merged (`4634669`) |
| 2 | I Integration | `feat/tracker-i-integration` | done, merged (`31267e1`) |
| 3 | Finish | `feat/activity-tracker` | next |

## Next step

Wave 3 (Finish), 1 session plus the user. Prompt: `Read PROGRESS.md. Do wave 3.` First ask the user before `./build.sh --install` and `/perf-check` (they use the real data). Read the decisions lists in `docs/tracker-progress/C.md` and `I.md` with the user.

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
- 1 commit at the end of each wave 0 / track / wave 3 on its own branch. Ask before any push or merge to `main`.
- `Feature.md` is the user's own notes. Never commit or delete it.
- `/perf-check` installs the release build and runs it on the user's real data. Ask the user first.

## Session log

| Date | Session | Done | Commit |
|---|---|---|---|
| 2026-11-09 | Design (local) | Grill, design page, spec, plan, goals, test notes, this file. This file replaces the old Sathi 2.0 handover (in git history before `5dfff66`). | `5dfff66` + this file |
| 2026-11-09 | Wave 0 (local, subagents) | Contracts: tracker types, Prefs/LiveState fields, ports, test support, engine stubs and hooks, constants, copy, metrics, colors, track files, CONTRACTS.md. Old engine enum `Activity` is now `HabitActivity`. Review clean after 1 fix round. 1492 + 764 tests pass, lint OK. | `2381f1f` |
| 2026-11-10 | Wave 1 (local, 6 parallel subagents in worktrees) | T1–T6 built test-first, each reviewed; fix rounds: T1 2, T3 1, T4 1, T5 1, T6 1. Merged in order T2 → T1 → T3 → T4 → T5 → T6 with `--no-ff`, no conflict; tests and lint after each merge. 1648 + 898 tests pass, lint OK, release build OK. Worktrees and track branches removed. | `b9896a8` |
| 2026-11-10 | Wave 2 (local, 2 parallel subagents in worktrees) | C and I built test-first, each reviewed; 1 fix round each (C: 2 Important, 3 Minor; I: 5 Important, 3 Minor). Merged C → I with `--no-ff`, no conflict. At merge: `fillEventAsk` and `closeEventNote` wired with `TrackerCalendarWiringTests`. 1721 + 921 tests pass, lint OK, release build OK. Worktrees and track branches removed. | `e238fcf` |

## Open items

- None in the design. Add problems found during coding here.
- Wave 0 minor findings, deferred to wave 2 track I or wave 3:
  - The backup always writes `"activities": []`.
  - The copy says "Yes, log it", but the spec says "Yes". "1 min" is hard-coded in the copy.
  - `usualLength` and the start/end minutes are not fully checked on decode.
  - The Meeting category color is the same as the Meditation buddy color. Meditation uses A99CF5, but the design page has C9B8FF.
  - `spaceKeyName` is in `Limits`.
- Wave 1 decisions (need the user's eye, change in wave 3 if wrong):
  - Done opens A with the Started row; the old activity ends only on Start or Skip in A. Spec rule 15 ("Done ends the activity now") must be reworded.
  - C still asks after tracker hours on a tracker day (rule 25), but never on a non-tracker day or a day off (G2).
  - A late "Still on it" confirms the activity only up to now (rule 22).
  - A recent chip starts the activity at once (P1), with that chip's text and category.
  - The activity month file uses `{"schemaVersion":1,"value":[...]}` (storage rule 2). The spec Storage line says "items"; fix the spec.
- Wave 1 items for track I (beyond the "Needs" lists in the track files):
  - Add `askEveryMinutes` to `TrackerPromptState`; C's "Yes, N min more" shows 15 until then.
  - The backup encodes `[Activity]`, so items and fields that the store keeps but cannot decode are not in the backup.
  - Away rows in the report have no Edit and no Delete.
  - Move the private copy strings and constants of T4, T5, T6 into `Copywriter` / `UIMetrics` / `Limits` (key codes in `ShortcutCapture`, `perRow` 3, bar widths, "1 days").
  - `TrackerDaysOffCard` copies `DayOffCalendar` (about 60 lines). Give the shared days-off card an accent and closure API, then delete the copy.
  - The global hotkey stays active while the user records a new shortcut.
- Wave 1 items for track C: recurring events share one `eventIdentifier` (dedupe by id + start); keep each `events()` read to 1 day; a deleted category falls back to the calendar name.
- Hand test (user, wave 3): lock, sleep, lid, ⌥⌘Space steps in `docs/tracker-progress/T3.md`. A closed lid with an external display may not post sleep; Away then starts at the idle deadline.
- Wave 1 minors (wave 3): a paused session turns off the idle check until midnight; D loses its Away details after a restart; the end-of-day popup does not show for a day whose activity ended at midnight; turning the tracker off ends the activity at now, not at confirmed-until; duplicate ids in one month file share extra keys; CSV defuse misses a leading tab.
- Wave 2 decisions (need the user's eye, change in wave 3 if wrong):
  - Away in the middle of a meeting: rule 22 cuts the event at the lock or the last input, so a 1-min lock logs 1 min of meeting. Should an `.event` activity run to `min(event end, back)`? This conflicts with P5.
  - Track C: an event that is already running when reading starts or the app restarts is not logged; it is offered as the first chip. Quiet time: ask-first waits; log-and-tell logs with no note. An event activity never ends by itself; at the event end A opens with the Started row. Full list in `docs/tracker-progress/C.md`.
  - Track C: a pending ask-first comes back after D, B, a session, or a time block, the same day, until answered. A late Yes trims the old activity and the Away around the event.
  - Track I: NEW badge removed from "Activity tracker" (sidebar width). "MY DAY" sits above "Time blocks". "Log activity" is a full-width row below the tool row (rule 41 says inside the tool row). Reports window 620 → 664 pt. A timed-out buddy session does not give A the keyboard (`promptByUser`).
- Wave 2 deferred (track I, reasons in `docs/tracker-progress/I.md`): the backup leaves out undecodable activity items; Away rows have no Edit/Delete or place change; report edits across midnight are not refused; the global shortcut stays active while recording a new one; no "input again" presence event, so D can show up to 60 s late after an idle Away.
- Hand tests for wave 3: keyboard focus of every prompt (G64), panel resize, 1 real Gmail event (G27), P5.
