# Phase 22: Main window fit and activity prompt fix

Status: plan approved 2026-11-15. No code yet, except commit `add07bb` (the earlier prompt work moved from `main`).

Design canvas (mockups): https://claude.ai/artifact/A6Whdb8gHxFnqC4Ub6Xe4z
- Row 1 "Default views": `Default` (Main window filling a 1440×900 screen, wide layout) and `Popup` (activity prompt 1040×720, no scroll).
- Row 2 "narrow layout": Today, Activities (edit drawer), Calendar (floating Stats panel), Reports (stacked), all at 720 px.

## Goal

The Main window opens filling the screen and works with macOS left/right tiling on every display. Its pages adapt below 900 px wide. The activity prompt has one fixed size of 1040×720, with no scroll, and a smooth drag inside and across displays.

## Decisions (grill Q1–Q24, all accepted)

### Main window
1. Use the macOS tiling (drag to an edge, the green button menu, Fn+Ctrl+arrows). Sathi builds no snap system.
2. Each open fills the `visibleFrame` of the display that has the mouse pointer. The menu bar and the Dock stay visible. It is not a full-screen Space; the green button still gives that.
3. No remembered frame: every open fills the screen again.
4. Minimum size 640×520, so half of a 1280 px screen fits.
5. A 28 px drag strip across the full width at the top. A drag moves the window. A double-click calls `zoom` (fill / restore). Buttons in the strip still work.
6. Moving to another display fits the window there and keeps its shape: full → full, left half → left half, right half → right half, a free size larger than the new display shrinks and moves inside it.

### Narrow layout (window width, not screen width)
7. Below 900 px the page uses the narrow layout. At 900 px and more it uses the wide layout (today's design, no change).
8. Sidebar: below 900 it shows the 64 px rail without a write to the saved `sidebarOpen`. Back above 900 it uses the saved choice. In narrow mode the rail button opens the full sidebar as an overlay.
9. Today: buddy grid 2 columns (not 4), Breakdown and Coming up stack, category table 1 column, header buttons under the greeting, page scrolls vertically.
10. Activities: the 330 px edit panel becomes a drawer from the right over the page, with a dim layer; Esc or a click outside closes it. The drawer starts below 1100 px (not 900), because at 960 the panel already squeezes the list. The 4 tiles stay in 1 row; the category table goes full width.
11. Calendar: the Stats side panel floats over the grid, opened by its toggle. Week keeps 7 columns. The edit panel uses the drawer of item 10.
12. Reports: the score card's 4 small rings wrap to their own row; the Categories card goes full width; the 440 px streak calendar stacks under it at full width. Buddy tabs do the same with the facts column and the month card.
13. Settings: only the calendar rows of Tracker and Time blocks change: the 210 px label goes above the list.

### Activity prompt
14. Every prompt kind has the same size: `min(1040×720, visible screen − 2 × promptScreenMargin)`.
15. No scroll. To fit 720: For and Ask me share one row; Away and Quiet share one row; the Keep button sits on the right of the running card, next to the name. Header and footer are fixed.
16. Only when the visible screen is shorter than 752 px does the body scroll, so the footer stays visible.
17. Keep the earlier work in `add07bb`: at most 5 calendar boxes then None and "+{n} more", the on-screen clamp.
18. Drag: the header hands the drag to macOS with `window.performDrag(with:)` through a small `NSViewRepresentable` behind the header. The keep-on-screen clamp runs once, on mouse-up.
19. Dropped across 2 displays, the prompt moves fully onto the display that holds the larger part of it.
20. A new prompt opens at the center of the display that has the mouse pointer (no change).

## Rules to update first
- `.claude/rules/business-logic.md` rule 3: replace "the running card and the form scroll" with items 14–16 and 18–19.
- `docs/ROADMAP.md`: add phase 22 and a decision log line.
- `GLOSSARY.md`: Narrow layout and Wide layout (done in `add07bb`).

## Tracks (parallel, one worktree each, branched from `feat/window-fit`)

| Track | Branch | Owns |
|---|---|---|
| A prompt | `feat/wf-prompt` | `Features/Tracker/Prompt/*`, `UIController+Tracker*.swift`, `PromptFit.swift`, `UIMetrics+ActivityPrompt.swift` |
| B window | `feat/wf-window` | `MainWindow.swift`, `UIController+Main.swift`, `WindowCloseWatcher.swift`, new `WindowFit.swift`, new `WindowDragStrip.swift`, `UIMetrics+MainWindow.swift` |
| C narrow | `feat/wf-narrow` | `MainView.swift`, new `MainLayout.swift`, `MainSidebar.swift`, Today / Activities / Calendar / Reports / Settings views |

C owns `MainView.swift` (min size at line 16, and it places B's drag strip). B only adds `WindowDragStrip`.
Each track: `test-writer` agent (failing tests) → implementer → `code-reviewer` agent.

### Track A: prompt
| Change | Where |
|---|---|
| Fixed size from item 14 | `ActivityPromptView.swift` (frame at the `.frame(width:)` / `.frame(maxHeight:)` lines), `PromptFit.size(screen:margin:)` |
| No scroll when it fits; scroll fallback only on a short screen | `ActivityPromptView.scrolling(_:)` |
| For + Ask me in one row; Away + Quiet in one row | `PromptForm` and its rows |
| Keep button on the right of the running card | `PromptRunningCard` |
| Native drag | `PromptHeader.swift` (drag gesture), new `PromptDragHandle.swift` |
| Clamp on drop to the display with the larger part | `PromptFit.dropped(frame:screens:margin:)`, `UIController+TrackerPanels.swift` (`moveTrackerPrompt`, `placeTracker`) |

Tests: `PromptFitTests` (size on large and short screens; drop across 2 displays picks the larger overlap; clamped inside margins). `ActivityPromptLayoutTests` (ViewInspector: no `ScrollView` when it fits, a `ScrollView` on a short screen; For and Ask me in one `HStack`; Away and Quiet in one `HStack`).

### Track B: window
| Change | Where |
|---|---|
| Fill the pointer display's `visibleFrame` on each open (replace `center()`) | `MainWindow.swift`, `UIController+Main.swift` `showMain` / `reopenMain` |
| Min size 640×520 | `UIMetrics+MainWindow.swift`, `MainWindow.swift` `contentMinSize` |
| Drag strip (drag + double-click zoom) | new `WindowDragStrip.swift` |
| Fit on display change, keep shape | `WindowCloseWatcher.swift` (`windowDidChangeScreen`), new pure `WindowFit.swift` |

Tests: `WindowFitTests` (open = pointer visible frame; full → full; left half → left half; right half → right half; free size larger than the target shrinks and moves inside; a few px tolerance for tiling gaps).

### Track C: narrow layout
| Change | Where |
|---|---|
| `MainLayout` (`isNarrow`, `drawerEdit`) from one `GeometryReader` in `MainView`, in the environment; it changes only when the width crosses 900 or 1100 | `MainView.swift`, new `MainLayout.swift` |
| Rail below 900 without writing `sidebarOpen`; overlay sidebar | `MainSidebar.swift` |
| Today narrow | `TodayPage.swift`, `TodayBuddyGrid.swift` (`todayBuddyColumns`), `TodayBreakdownCard.swift` (`CategoryTableView(columns:)`) |
| Activities drawer below 1100; top row stacks | `ActivityDayView.swift` |
| Calendar floating Stats panel; edit drawer | `CalendarPage.swift`, `CalendarPage+Edit.swift` |
| Reports stacking | `ReportsScoreCard.swift`, `ReportsAllTab.swift`, `ReportsBuddyTab.swift` |
| Settings calendar rows | `TrackerCalendarCard.swift`, `BlockDefaultCalendarRow.swift` |

Tests: `MainLayoutTests` (899 narrow, 900 wide; 1099 drawer, 1100 no drawer). ViewInspector per page in narrow mode: rail shows and `sidebarOpen` is unchanged; Today has 2 columns; Activities edit panel is an overlay; Calendar side panel is an overlay; Reports cards are in a `VStack`.

## Constants
- `UIMetrics+MainWindow.swift`: `mainWindowMinSize` 640×520, `mainNarrowBelow` 900, `mainDrawerBelow` 1100, `mainDragStripHeight` 28.
- `UIMetrics+ActivityPrompt.swift`: `activityPromptWidth` 1040, `activityPromptHeight` 720, `promptPairGap`.

## Performance
No new timers or animations. `MainLayout` changes only on a threshold crossing. The native drag replaces the SwiftUI gesture. After the merge: `./build.sh --install`, `./scripts/perf.sh`; the user runs `./scripts/perf.sh --windows`.

## Finish
1. Merge A, B, C into `feat/window-fit`. Run `./scripts/test.sh`, `./scripts/lint.sh`, `swift build -c release`, install, `perf.sh`, and a `code-reviewer` pass on the whole diff. Check the real prompt height (720 fits, no scroll) in the installed app.
2. Before merging into local `main`, clean `main`'s working tree of the files that `add07bb` moved (they are identical to the commit): restore the 15 tracked files and delete the 6 untracked files listed in `add07bb`, and remove the Narrow/Wide terms from `main`'s `GLOSSARY.md`. Leave `Feature.md`, `AGENTS.md`, `.codex/`, the PNG, and the To-dos glossary lines alone. Set those aside with a tagged stash (`git stash push -u -m phase22-unrelated`), merge, then `git stash apply <sha>` and drop it.
3. Merge `feat/window-fit` into local `main`. Do not push. Remove the track worktrees and branches.
4. `/sathi-website` afterwards for the user-visible change.

## Risks
- `performDrag` needs the mouse-down `NSEvent`, so the header needs an AppKit view behind it.
- The "same half" guess uses a tolerance, because macOS tiling can add small gaps.
- The 720 height is an estimate from the mockup. Check it in the running app.
