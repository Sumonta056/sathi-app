# Phase 19 — Main window v2 plan

Spec: `docs/specs/phase-19-window-v2.md` (binding). Mockups: `docs/design/phase-19/`.
Base branch: `feat/app-window`. Each track runs in its own git worktree and branch, then merges back.

## Global Constraints

- Read `CLAUDE.md` and `.claude/rules/` before coding. Max 200 lines per file, no comments,
  no magic numbers, `package` access only where another target needs it.
- Tests first (Swift Testing for Core, ViewInspector for SathiUI). No real waits.
- New sizes in a NEW `Sources/SathiUI/Constants/UIMetrics+<Track>.swift`; new words in a NEW
  `Sources/SathiCore/Formatting/Copywriter+<Track>.swift`. Do not edit another track's files.
  Avoid editing shared files (`UIMetrics.swift`, `Copywriter.swift`, `NightPalette.swift`) —
  if you must, add lines at the END only, to keep merges clean.
- Chips are square (radius 6). No round pills, no dropdown menus for choices, no shadows.
- Done = `./scripts/test.sh` passes, `./scripts/lint.sh` passes, `swift build -c release` clean.
- Commit on your track branch when done (conventional commit, scope `window-v2`). Never push.

## Task 0: Shared category table (Spec S1)

Branch `feat/window-v2-core` in worktree `../Sathi-w2-core`. Runs FIRST, alone.

- Core: a pure builder that turns category totals into rows: name, color hex, seconds,
  hours text (existing `Fmt`), percent text (rule in S1, "<1%"), optional change text
  against a previous-range total. Sorted largest first. Tests for rounding, "<1%", sort,
  empty input, change text signs ("+40m", "−12m", "0m").
- UI: `Sources/SathiUI/Components/CategoryTable.swift` (+ helpers if needed): header slot
  (total + muted line), 100% bar, table in 1 or 2 columns (parameter), optional change column.
  ViewInspector tests: row count, column count, percent text shown, change column shown/hidden.
- Do not change any page yet.

## Task A: Activities page (Spec S2, S3)

Branch `feat/window-v2-activities`, worktree `../Sathi-w2-act`, from Task 0's merge.
Files: `Sources/SathiUI/Features/Reports/Activities/*`, Core edit API and `ActivityEdit`.
1. S3 Core first (business-logic.md, then tests, then code): calendar choice on edit.
2. Top row (S1 card 2/3 + 4 tiles 1/3).
3. Timeline rows (new row view), height buckets, gap rows, away rows, pencil button.
4. Inline edit section (replace the current edit form presentation), length chips,
   category chips, calendar chips. Delete the old row/edit views the new ones replace.

## Task B: Reports page (Spec S4, S5)

Branch `feat/window-v2-reports`, worktree `../Sathi-w2-rep`, from Task 0's merge.
Files: `Sources/SathiUI/Features/Reports/*.swift` (not `Activities/`), `Sources/SathiCore/Stats/*`.
1. Core: per-day per-buddy goal state for a month (for S5a dots and S5b cells), score card
   numbers (goals met/possible, per-buddy goal days, best/weakest buddy headline), day-by-day
   grid values. Extend `ReportScreen`/builders; tests first.
2. Tabs, All buddies tab (score card, day grid, S1 card one column with change + Away,
   S5a calendar), buddy tab (chart, facts, S5b calendar). Fix the tab overlap bug.
3. Delete views the new layout replaces.

## Task C: Today page (Spec S6)

Branch `feat/window-v2-today`, worktree `../Sathi-w2-today`, from Task 0's merge.
Files: `Sources/SathiUI/Features/Today/*`.
1. Split `TodaySoFarCard` into the full-width ribbon card and the Breakdown card (S1, 2 columns).
2. Restyle `TodayComingUp` rows (icon tile, time + detail, "in N min" badge). Equal heights.

## Task D: Sidebar (Spec S7)

Branch `feat/window-v2-sidebar`, worktree `../Sathi-w2-side`, from the current
`feat/app-window` head. Independent of Task 0 — runs in parallel with it.
Files: `Sources/SathiUI/Features/Main/*`, footer views in `Features/Settings/` (reuse
`Links`, version text), a storage key for the open/closed state (`StorageKeys.swift`, add at end).
1. Open/close button and the 64 pt rail.
2. Settings list always open, icon tiles per page.
3. Tracker block kept; one-line footer with version + GitHub + portfolio.

## Merge order

Task 0 → `feat/app-window`. Then A, B, C (parallel) and D merge into `feat/app-window` one at a
time, each followed by `./scripts/test.sh` and `./scripts/lint.sh` on the merged head.
Then `./build.sh --install` for the user's hand test.
