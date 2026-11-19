# Phase 26: Dashboard (Today + Reports in one page)

Status: plan approved 2026-11-19. No code yet.
Design canvas: https://claude.ai/artifact/FfUGQ7LCFnq4BmRn2LJGTH (3 boards: Day · All buddies, Week · All buddies, Week · Fota tab).

## 1. Goal

Merge the Today page and the Reports page into 1 page, "Dashboard". One Day / Week / Month switch picks what the page shows. Reorder the sidebar and add a "PLAN" group for To-dos and Calendar.

No saved-data change. No new timer. No new dependency.

## 2. Approved decisions

| # | Decision |
|---|---|
| D1 | Sidebar order: Dashboard, Activities, then the group heading "PLAN" with To-dos and Calendar, then "SETTINGS" (no change). |
| D2 | The name of the group is "PLAN". The item keeps the name "To-dos" (not "Reminders"). |
| D3 | Dashboard has a range switch Day / Week / Month with ‹ › and the range title, the same `RangeBar` that Reports uses now. |
| D4 | The buddy tab row ("All buddies", "Fota · 2/7", …) shows on every range, also on Day. |
| D5 | Day + All buddies = the Today content. Week or Month + All buddies = the Reports "All buddies" content. Any range + a buddy tab = the Reports buddy tab content (chart, facts, buddy month calendar). |
| D6 | Option B: on Day + All buddies, a score line under the greeting: "{met} of {possible} goals today · {change vs yesterday}". |
| D7 | Day + All buddies shows the streak month calendar (the Reports `StreakOverviewCard`) in the lower row, left of Coming up. |
| D8 | The Breakdown card is removed. Its categories become 1 line in the "Today so far" card, under the timeline: dot, name, time, percent. "Today so far" also shows the change in logged time vs yesterday. |
| D9 | The To-dos sidebar item shows a coral count badge: the number of to-dos due today or overdue (To-dos rule 7). No badge at 0, or when To-dos is off or has no access. |
| D10 | Header buttons: Day keeps "Quick reminder" and "Take a break". Week and Month show "Export CSV" (the Reports button) in place of "Quick reminder". |
| D11 | Page title: Day shows the greeting (as Today does now). Week and Month show "Dashboard". The date eyebrow stays on every range. |
| D12 | Cleanup is approved: delete the old Today/Reports page split, dead code, dead constants, dead copy, and dead tests (section 8). |
| D13 | A past Day (after ‹) with All buddies shows the Reports "All buddies" content for that day. Only the day that holds now shows the Today content. |
| D14 | The Quick panel link "Reports" is renamed "Dashboard" and opens Dashboard on Day. |
| D15 | The PLAN heading hides when both To-dos and Calendar are off. |
| D16 | In the narrow rail the To-dos count is a small coral dot on the To-dos icon; its tooltip and accessibility label say "{n} due today". |

Default left to the implementer: the sidebar icon for Dashboard is `square.grid.2x2`.

## 3. Business rule changes (do first, in `.claude/rules/business-logic.md`)

Change this file before any code (project rule 9).

### Main window rule 2 (replace)

> 2. Sidebar: logo and name, then Dashboard, Activities, then the heading "PLAN" with To-dos (only when To-dos is on) and Calendar (only when the Calendar page switch is on; no tag in the sidebar or the rail, the word "experimental" shows only in Settings → General). The PLAN heading shows only when 1 or more of its items show. Then Settings and the status block ("TRACKER ON" with hours and "asks every {n} min", or "TRACKER OFF"). To-dos shows a count badge with the number of to-dos due today or overdue (To-dos rule 7) when To-dos is on, has access, and the count is more than 0. When Settings is selected, its sub-pages show nested below it: General, Fota, Boi, Shanti, Shokti, Quick reminders, Activity tracker, Time blocks, To-dos, Sound. The first open of Settings selects General. The rail shows the same items in the same order, with a divider in place of each heading.

### Main window rule 3 (change the Reports paths)

- menu "Dashboard" (was "Reports") → Dashboard, Day range, All buddies.
- Every other path that opened Today opens Dashboard, Day range, All buddies.

### Main window rule 8 (change)

"and links Reports, Settings, Quit" → "and links Dashboard, Settings, Quit". "It closes when the user picks Open Sathi, Reports, or Settings" → "It closes when the user picks Open Sathi, Dashboard, or Settings".

### Main window rule 5 (change)

"open the main window on Today" → "open the main window on Dashboard, Day range".

### Main window rule 7 (add 1 sentence)

> The Dashboard range and tab are page state: each open starts on Day (or on the asked range) and All buddies.

### Main window rule 9 (replace)

> 9. Dashboard page (phase 26 spec), Settings pages (spec 20–26), and performance (spec 55) follow the spec. The Day range with All buddies changes at most 1 time per minute plus at once on a real data change, with no timer of its own.

### Main window rule 15 (change the page names)

"Today uses 2 buddy columns, stacks Breakdown and Coming up" → "Dashboard Day uses 2 buddy columns, stacks the streak calendar and Coming up". "Reports wraps the score rings" → "Dashboard Week and Month wrap the score rings".

### New section "Dashboard" (add after "Main window")

1. Dashboard has 1 range switch (Stats rule 14) and 1 tab row (Stats rule 8). Both stay while the user moves between ranges; a range change keeps the selected tab.
2. Day + All buddies shows: the date eyebrow, the greeting, the score line, Now, the 4 buddy cards, "Today so far", the streak month calendar, and Coming up.
3. The score line: "{met} of {possible} goals today" from the day `ReportsOverview` score, then " · " and its change text ("+1 vs yesterday", "same as yesterday"). With no buddy on, the line is hidden. With no data in both days, the change part is hidden (Stats rule 15).
4. "Today so far" shows the logged total and its change vs yesterday (Stats rule 15, Day words), the timeline, and 1 breakdown line: each category (dot, name, time, percent), longest first, away rows last with "—" (Activity tracker rule 11b). With the tracker off the card shows as now.
5. Day + All buddies on a past day (‹): the page shows the Reports "All buddies" content for that day, as Reports does now. Only the day that holds now shows the Today content.
6. Week or Month + All buddies: Reports rule 8. Any range + a buddy tab: Reports rule 9.
7. The streak calendar on Day opens on the current month (Stats rule 11).

### Stats and reports rule 8 (change 1 word)

"Reports page (spec S4)" → "Dashboard Week and Month, and a past Day (spec S4)".

### Roadmap decision row (add to `docs/ROADMAP.md`)

`| 2026-11-19 | Phase 26: Today and Reports become 1 Dashboard page with one Day / Week / Month switch; sidebar Dashboard, Activities, PLAN (To-dos, Calendar). No saved-data change. |`

## 4. Behavior details

### 4.1 Routing

`MainPage` changes:

```swift
package enum MainPage: Equatable, Sendable {
    case dashboard(ReportRange)
    case todos
    case activities(DayKey?)
    case calendar(DayKey?)
    case settings(SettingsPage)
}
```

- `.today` and `.reports` are removed (no alias kept; cleanup approved).
- `Engine.openMain(.dashboard(.day))` replaces `openMain(.today)`.
- `Engine.openReports()` is deleted. Its 1 caller (`QuickLinks`) calls `openMain(.dashboard(.day))` (D14).
- `MainRoute.settle` falls back to `.dashboard(.day)`.
- `MainView` falls back to `DashboardPage(kind: .day)` where it shows `TodayPage()` now.

`MainPage` is not saved, so there is no migration (`storage.md` does not apply). Check: `grep -rn "MainPage" Sources/SathiCore/Storage` must give nothing.

### 4.2 Dashboard page state

`DashboardPage` holds `@State picked: StatsRange?` and `@State selected: HabitID?`, like `ReportsPage` now. Start range = `e.currentRange(kind)`.

Which content shows:

| Range | Holds now | Tab | Content |
|---|---|---|---|
| Day | yes | All buddies | `TodayDayContent` (the old Today, with D6, D7, D8) |
| Day | no | All buddies | `ReportsAllTab` |
| Week / Month | any | All buddies | `ReportsAllTab` |
| any | any | a buddy | `ReportsBuddyTab` |

Put this choice in a static pure function `DashboardPage.content(range:now:selected:) -> DashboardContent` (enum `today`, `all`, `buddy(HabitID)`), so a unit test covers the table without ViewInspector state (testing rule on `@State`).

### 4.3 Header

One `DashboardHeader` view for every range:
- Eyebrow: date line (`TodayScreen.dateLine`).
- Title: greeting on Day that holds now; else "Dashboard".
- Score line (D6) only on Day that holds now with All buddies.
- Right side: `RangeBar`, a 1 px divider, then Day: "Quick reminder" + "Take a break" (the current `TodayHeader` buttons); Week / Month / past Day: `ReportsExportButton`.
- Narrow (< 900 px): the right side wraps below the title (reuse `PageHeaderLayout`).

### 4.4 Day content (Day + All buddies + holds now)

Order: Now card, buddy grid, Today so far (with breakdown line), lower row.
- Lower row wide: `StreakOverviewCard` (fixed width from `reportsCalendarWidth()`) + `TodayComingUp` (fills the rest).
- Lower row narrow: stacked, calendar first.
- The page scrolls when the content is taller than the window (now it scrolls only when narrow). Use 1 `ScrollView` for every width. Check that Coming up does not need `maxHeight: .infinity` any more.

### 4.5 Performance

- Day content still redraws from `TodayModel` (1 time per minute plus real changes).
- `StreakOverviewCard` has its own `RangeMemo`; its month does not change each minute, so the memo must hit. Add a test that 2 builds with 2 `now` values in the same day call `streakOverview` 1 time (use the existing `RangeMemoTests` pattern).
- The score line and the "vs yesterday" change need yesterday's data. Compute them in Core once per day key plus data version (`RangeMemo` keyed by the day range), never in `ForEach` and never every minute without a cache.
- The To-dos badge reads `e.quickTodos` (already cached for the Quick panel). No new read of Reminders.

## 5. Core changes (SathiCore)

| File | Change |
|---|---|
| `Models/MainPage.swift` | Section 4.1 enum. |
| `Engine/Engine+Actions.swift` | Delete `openReports()` (D14). |
| `Formatting/Copywriter+QuickPanel.swift` | `quickPanelReports = "Reports"` → `quickPanelDashboard = "Dashboard"`. |
| `Today/TodayScreen.swift` | `TodaySoFar` gains `change: RangeChange` (logged today vs yesterday, cut at the same time as now, Stats rule 15). `TodaySoFar.off` gets `.none`-style empty change. |
| `Engine/Engine+Today.swift` | Fill `sofar.change` from the day `ActivityRangeStats` (reuse `activityRange(_:)`, which already holds the previous range). |
| new `Engine/Engine+Dashboard.swift` | `dashboardScore: DashboardScore?` = day `reportsOverview(currentRange(.day)).score` mapped to `met`, `possible`, `changeText`, `isUp`; `nil` when no buddy is on. `todosBadgeCount: Int` = due-today + overdue from `quickTodos`, 0 when off or no access. |
| new `Formatting/Copywriter+Dashboard.swift` | `mainPageDashboard = "Dashboard"`, `sidebarPlanHeading = "PLAN"`, `dashboardScoreLine(met:possible:change:)`, `todaySoFarChange(_:)` (reuse `rangeChange(_:kind: .day)`), `todosBadge(_:)` (accessibility: "{n} due today"). |
| `Formatting/Copywriter+Main.swift` | Remove `mainPageToday`, `mainPageReports` (cleanup). |
| `Formatting/Copywriter+TodayV2.swift` | Remove `todayBreakdownTitle` (cleanup). |

Each file stays under 200 lines. `Engine+Today.swift` is 116 lines now; if the change pushes it near 200, put the so-far change in `Engine+TodaySoFar.swift`.

## 6. UI changes (SathiUI)

### New folder `Features/Dashboard/`

| File | Job |
|---|---|
| `DashboardPage.swift` | Range and tab state, content choice (4.2), scroll, padding. |
| `DashboardContent.swift` | The `DashboardContent` enum and the static `content(range:now:selected:)` function. |
| `DashboardHeader.swift` | 4.3. |
| `DashboardScoreLine.swift` | D6 text view. |
| `TodayDayContent.swift` | 4.4: Now, buddies, so far, lower row. Moved from `TodayPage.content`. |
| `TodayLowerRow.swift` | Streak calendar + Coming up, wide and narrow. |

### Changed

| File | Change |
|---|---|
| `Features/Main/MainView.swift` | Route `.dashboard(kind)` → `DashboardPage(kind:)`; fallbacks to `.dashboard(.day)`. |
| `Features/Main/MainRoute.swift` | `settle` falls back to `.dashboard(.day)`. |
| `Features/Main/MainSidebar.swift` | D1, D9: new order, PLAN heading, badge. Split out `SidebarPlanGroup.swift` if the file passes 200 lines. |
| `Features/Main/SidebarRail.swift` | Same order; divider in place of the PLAN heading; badge as a small coral dot on the To-dos icon. |
| new `Features/Main/SidebarBadge.swift` | The coral count pill (`Night.tracker` on `Night.trackerFill`). |
| `Features/Main/MainSidebarItem.swift` | Optional trailing badge. |
| `Features/Today/TodaySoFarCard.swift` | Change text next to the total; breakdown line under the hour labels (D8). Split `TodaySoFarBreakdown.swift` out if needed. |
| `Features/Today/TodayHeader.swift` | Its buttons move into `DashboardHeader`; keep only what `DashboardHeader` reuses, or delete it (8). |
| `Features/MenuBar/OpenSathiButton.swift` | `.dashboard(.day)`. |
| `Windows/UIController+Main.swift` | `reopenMain` → `.dashboard(.day)`. |
| `Sources/Sathi/AppDelegate.swift` | `.dashboard(.day)`. |
| `Constants/UIMetrics+Sidebar.swift` | Badge sizes, PLAN heading padding (reuse the SETTINGS heading constants where they match). |
| new `Constants/UIMetrics+Dashboard.swift` | Score line font and gap, lower row gap, breakdown line spacing. |

## 7. Tests first

Write these before the code. Expected values come from the rules in section 3, not from running code.

Core (`Tests/SathiCoreTests/`):
- `EngineMainPageTests`: `openMain(.dashboard(.day))`, launch path gives `.dashboard(.day)`.
- `CopywriterQuickPanelTests`: the link text is "Dashboard".
- UI `QuickLinks` test (extend the existing Quick panel test): the "Dashboard" link opens `.dashboard(.day)` and closes the panel.
- new `EngineDashboardScoreTests`: met/possible from a fixture day; change text "+1 vs yesterday", "same as yesterday"; `nil` with all buddies off; change hidden with no data both days.
- new `EngineTodaySoFarChangeTests`: logged change vs yesterday cut at the same clock time (Stats rule 15); tracker off gives no change.
- new `EngineTodosBadgeTests`: count = due today + overdue; 0 when To-dos off; 0 without access; hidden lists do not count (To-dos rule 8).
- new `CopywriterDashboardTests`: every new string.
- `RangeMemoTests` (or new `DashboardMemoTests`): the streak overview builds 1 time across 2 minute ticks in the same day.

UI (`Tests/SathiUITests/`):
- new `DashboardContentTests` (pure function): the table in 4.2, every row.
- new `DashboardPageTests`: Day shows the greeting, the score line, "Today so far", the month title, Coming up, no "Breakdown" title; Week shows "Dashboard", "Day by day", "Time by category", "Export CSV"; a buddy tab shows the buddy facts.
- new `SidebarOrderTests` (or extend `TodosNavigationTests`): item order; PLAN hidden when both off (D15); PLAN shows with only Calendar on; badge text "3" and hidden at 0; rail dot shows with label "3 due today" and hides at 0 (D16).
- `DashboardContentTests`: a past Day with All buddies gives `all`, today gives `today` (D13).
- `Narrow/NarrowLayoutTests`, `Narrow/NarrowPageTests`: Dashboard Day stacks calendar and Coming up; Week wraps the score rings.
- `TodayPageFirstFrameTests`: move to `DashboardPageFirstFrameTests` (the first frame still has content before `onAppear`).
- `WebsiteShots`: Today and Reports shots become Dashboard Day and Dashboard Week.

## 8. Cleanup (approved)

Do this as the last track, after the feature tracks merge, so no track loses a file it still needs.

Delete:
- `Features/Today/TodayPage.swift` (content moves to `TodayDayContent`).
- `Features/Today/TodayBreakdownCard.swift` (D8).
- `Features/Reports/ReportsPage.swift` (state moves to `DashboardPage`).
- `Features/Today/TodayHeader.swift` if `DashboardHeader` took all of it.
- `MainPage.today`, `MainPage.reports`, `Copywriter.mainPageToday`, `mainPageReports`, `todayBreakdownTitle`, `quickPanelReports`, `Engine.openReports()`.
- Constants with no user left: `todayLowerWeights`, `todayBreakdownColumns`, `todayBreakdownColumnsNarrow`, `todayBreakdownGap`, and any other that `grep` shows unused (step below).
- Tests of deleted views: `TodayPageTests`, `TodayV2Tests` parts for Breakdown, `ReportsPageTests` (move every case that still applies into `DashboardPageTests` first; never delete a test that still covers live behavior).

Find dead constants and copy with a script, not by eye:

```bash
for n in $(grep -ohE "static (let|var|func) [a-zA-Z0-9_]+" Sources/SathiUI/Constants Sources/SathiCore/Formatting | awk '{print $3}' | sort -u); do
  c=$(grep -rwn "$n" Sources Tests | grep -v "static \(let\|var\|func\) $n" | wc -l)
  [ "$c" -eq 0 ] && echo "$n"
done
```

Remove only the names in this list that this phase made dead. Report other dead names to the user; do not delete them in this phase.

Move or keep: `Features/Reports/*` cards stay where they are (`ReportsAllTab`, `ReportsBuddyTab`, `ReportsScoreCard`, …); only the page file goes. Rename `Features/Reports/` is out of scope.

Docs:
- `CLAUDE.md`: first paragraph (Dashboard page), module map (`Features/Dashboard/`, remove `TodayPage`, `ReportsPage`, Breakdown).
- `README.md`: page names and screenshots.
- `docs/specs/phase-18-app-window.md` and `phase-19-*`: add 1 line at the top "Today and Reports pages are replaced by the Dashboard (phase 26)". Do not rewrite old specs.
- `docs/ROADMAP.md`: phase 26 entry and decision row.
- Website (`/sathi-website`): text, Today/Reports screenshots → Dashboard Day/Week, alt text.

## 9. Parallel development with worktrees and subagents

### 9.1 Branches

- Base: `feat/dashboard` from `main`.
- Note: `feat/calendar-plan-actual` (phase 25) is open and not merged. It touches `Features/Calendar/` and Calendar copy and metrics. This phase does not touch those files. The shared files are `Copywriter+*.swift` and `UIMetrics+*.swift`; this phase only adds new files there (`Copywriter+Dashboard.swift`, `UIMetrics+Dashboard.swift`) and removes lines from `Copywriter+Main.swift` and `Copywriter+TodayV2.swift`, so a merge conflict is unlikely.
- Each track has its own worktree: `../Sathi-dash-<track>` on branch `feat/dashboard-<track>`, from `feat/dashboard` after Track 0.

### 9.2 Tracks

```
Track 0 (main session, serial)  ──►  A ─┐
                                      B ─┼──► merge into feat/dashboard ──► Track D (cleanup, serial) ──► checks
                                      C ─┘
```

**Track 0: contract (main session, no subagent).** About 30 min. Must merge before A, B, and C start.
1. Business rules (section 3) and ROADMAP row.
2. `MainPage` enum (4.1) and every `switch` and caller, so the build is green: route `.dashboard(.day)` to the existing `TodayPage()` and `.dashboard(.week/.month)` to the existing `ReportsPage()` for now.
3. Empty `Copywriter+Dashboard.swift` with `mainPageDashboard` and `sidebarPlanHeading`; empty `UIMetrics+Dashboard.swift`.
4. `DashboardContent` enum and the signature of `DashboardPage.content(range:now:selected:)` (body may `fatalError` only in Track 0; Track B fills it).
5. `swift build`, `./scripts/test.sh EngineMainPageTests` (update its cases), commit "phase 26: dashboard contract".

**Track A: sidebar and routing.** Owns: `Features/Main/*`, `Features/MenuBar/OpenSathiButton.swift`, `Features/MenuBar/QuickLinks.swift` (D14 rename), `Copywriter+QuickPanel.swift`, `Engine+Actions.swift` (`openReports` removal), `Windows/UIController+Main.swift`, `Sources/Sathi/AppDelegate.swift`, `UIMetrics+Sidebar.swift`, Core `todosBadgeCount` + its Copywriter badge text.
Tests: `SidebarOrderTests`, `EngineTodosBadgeTests`, `EngineMainPageTests`.

**Track B: Dashboard page shell.** Owns: new `Features/Dashboard/DashboardPage.swift`, `DashboardContent.swift`, `DashboardHeader.swift`, `DashboardScoreLine.swift`; Core `Engine+Dashboard.swift` (`dashboardScore`) and the score Copywriter strings. It embeds the current `TodayPage` content view unchanged for the "today" case (Track C changes the inside).
Tests: `DashboardContentTests`, `DashboardPageTests` (header and range parts), `EngineDashboardScoreTests`, `CopywriterDashboardTests` (score part).

**Track C: Day content.** Owns: `Features/Today/*` (except the header buttons Track B moves), new `Features/Dashboard/TodayDayContent.swift`, `TodayLowerRow.swift`, `TodaySoFarCard` breakdown line, Core `TodaySoFar.change`, `Engine+Today.swift`, and its Copywriter text.
Tests: `EngineTodaySoFarChangeTests`, `DashboardMemoTests`, `DashboardPageTests` (Day content parts), narrow tests for Day.

File ownership is strict: a track never edits a file another track owns. When a track needs a change in another track's file, it writes the need in its final report and the main session makes the change at merge.

**Track D: cleanup and docs (main session or 1 subagent, serial, after merge).** Section 8, then `/sathi-website`.

### 9.3 Subagents per track

Each track runs the project loop (memory: subagents per phase):

1. `test-writer` writes the failing tests listed for the track. It writes only under `Tests/`.
2. Implementer: `general-purpose` (or `pstack:poteto-agent`) with `isolation: "worktree"` makes the tests pass in the track worktree.
3. `code-reviewer` reviews the track diff against the project rules.
4. The implementer fixes the review findings. The main session reads the report and runs `./scripts/test.sh <suite>` and `./scripts/lint.sh` in the worktree itself before the merge.

Run A, B, and C in 1 message so they run at the same time (3 test-writers, then 3 implementers, then 3 reviewers). Max 9 subagents for the 3 tracks; Track D adds 1 at most.

Every subagent brief must contain:
- The goal of the track, the files it owns, and the files it must not touch (9.2).
- The path to this spec and to `.claude/rules/business-logic.md` sections "Main window" and "Dashboard".
- The worktree path and branch.
- "No code comments. Max 200 lines per file. Constants in `UIMetrics` / `Limits`. Tests first. No `Date()` in Core."
- "Right after you read the brief, call the savvy-progress `step` tool with your plan as `total` (3 to 8 steps) and `done: 0`. Call it again with the new `done` and a short `note` after each step."
- "Report: files changed, test command and its real pass/fail count, anything you need from another track."

### 9.4 Merge order

1. Merge A into `feat/dashboard`. Build and test.
2. Merge C. Build and test.
3. Merge B (it embeds C's `TodayDayContent`; switch the "today" case from the old content to `TodayDayContent` in this merge). Build and test.
4. Track D.
5. Commit on feature branches without asking (memory: commit without asking). Ask before merge to `main` and before every push.

## 10. Definition of done

1. `./scripts/test.sh` passes. Report the real counts.
2. `./scripts/lint.sh` passes (200-line limit, no comments).
3. `swift build -c release` has no new warnings.
4. `./build.sh --install`, then `./scripts/perf.sh` passes (idle CPU < 1%, memory < 40 MB fresh, < 10 wakeups/min). The user runs `./scripts/perf.sh --windows` in Terminal (< 50 MB after a window, cycle 2 adds < 3 MB).
5. `ui-verifier` compares the running app with the canvas boards (export the 3 boards to `docs/design/phase-26-*.png` first).
6. Screenshot the installed app at 1440 wide and at 800 wide (narrow) before saying the layout is right (memory: verify UI fix in app).
7. Hand test: launch opens Dashboard Day; menu "Open Sathi" → Day; menu "Dashboard" link → Day; ‹ on Day shows yesterday's report content; tab stays when the range changes; To-dos badge count matches the Quick panel "Due today" card; PLAN hides with To-dos and Calendar both off; end-of-day "Open full report" still opens Activities.
8. README, `CLAUDE.md`, ROADMAP, and website updated (section 8).

## 11. Risks

| Risk | Guard |
|---|---|
| Day page now builds the streak calendar and yesterday's data each minute | `RangeMemo` per day key; memo test in Track C; `perf.sh`. |
| ViewInspector cannot see `@State` range changes | Static `content(range:now:selected:)` test; build the view in each state. |
| Day page taller than the window | 1 `ScrollView` on every width; hand test at the minimum size 640×520. |
| A track edits another track's file | Strict ownership table; reviewer checks `git diff --stat` against it. |
| Phase 25 branch conflicts | This phase adds new Copywriter/UIMetrics files and does not touch `Features/Calendar/`. |

## 12. Start prompt for the fresh session

> Read `docs/specs/phase-26-dashboard.md`. Do Track 0 yourself on a new branch `feat/dashboard`. Then run Tracks A, B, and C in parallel worktrees with subagents as section 9 says, merge them in the order of 9.4, do Track D, and finish the definition of done in section 10. Ask me before merge to `main` and before any push.
