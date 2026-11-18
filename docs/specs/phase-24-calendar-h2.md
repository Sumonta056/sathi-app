# Phase 24: Calendar Week redesign (design H2) and the event pop-up fix

Status: plan approved on 2026-11-18. The website screenshot step (B8) waits for later.

Design: board **H2** on the canvas https://claude.ai/artifact/MqDQoohF24VV4m9bKQzhX9

Do the work in 2 tracks on 2 branches. Each track uses the `/feature` loop: plan, failing tests, code, checks, review.

| Track | Branch | Size | Order |
|---|---|---|---|
| A. Event pop-up fix | `fix/event-ask-held` | Small, Core only | First |
| B. Calendar redesign (H2) | `feat/calendar-week-h2` | Large, Core and UI | Second |

The tracks change different files, so they can run in parallel in 2 worktrees under `.worktrees/`.

---

## Track A: Event pop-up fix

**Goal:** calendar events come first. A calendar event in a ticked calendar always asks the user at its start time, on top of any other pop-up and during a busy state. Only Away and a full-screen lock make it wait, and then it asks when they end, while the event is still on. Sathi never skips an event.

**Root cause** (`Sources/SathiCore/Engine/Engine+TrackerCalendarTick.swift`):
1. `:90`: in "Ask first" mode, when another pop-up is open, the code returns without setting `pendingAsk`. The event is lost.
2. `:65`: a pause, a running time block, or a buddy session at the start time drops the event.
3. `:63`: `checkedUntil` moves forward first, so a dropped event is never seen again.
4. `:100`: the code asks again only on the same day. It does not check that the event is still on.

Evidence: on 16 Nov, Away ended at 12:55, a pop-up was most likely still open at 13:00, and the 13:00 event got no row. The 10:30 event on the same day was logged as normal.

**Changes (Q1 answer: "ask at once, on top"):**
1. **On top of another pop-up.** `handleEventStart` (`:89-93`): when another tracker pop-up is open (Welcome back, the shortcut prompt, a To-do due prompt, "What now?" with a switch time, "Still on it?"), the event pop-up replaces it at once. Sathi keeps the replaced pop-up in a new runtime field, `trackerCalendarRuntime.heldPrompt`. When the event pop-up closes (any answer), the held pop-up shows again. A held To-do due prompt keeps its to-dos (To-dos rule 11).
2. **During a busy state.** `handleEventStarts` (`:65`): a pause, a running time block, or a buddy session no longer drops the event. The event pop-up shows at the start time. The busy state keeps running. The pop-up only asks; it never stops the time block or the session by itself.
3. **"Log and tell" mode with a busy tracker or another pop-up open:** Sathi does not log by itself. It shows the event ask pop-up, the same as in "Ask first" mode. "Log and tell" keeps its current behavior only when nothing else is open and the tracker is not busy.
4. **Only Away and a full-screen lock make it wait.** Then Sathi keeps the event in `pendingAsk`. `askPendingEventAgain` (`:97-106`) asks when the user is back or the lock closes, only when `n < e.end`, and the event is not logged or dismissed. This replaces the same-day check. The Away path (`Engine+TrackerCalendarAway.swift`) is not changed.
5. When 2 events start close together, the later one replaces the earlier event pop-up. The earlier event goes to `pendingAsk` and asks next, if it is still on. An event that is over is never asked.

**Rule first:** update `.claude/rules/business-logic.md`, Activity tracker rules 2 and 7: "Calendar events come first. An event ask shows at the event start, on top of any other tracker pop-up (which comes back after), and also during a pause, a time block, or a buddy session. Only Away and a full-screen lock make it wait; then it asks when they end, while the event is still on. In Log and tell mode, a busy tracker or an open pop-up gives the ask instead of a silent log." Also update To-dos rule 11: an event ask holds an open To-do due prompt.

**Tests** (new files `Tests/SathiCoreTests/Tracker/EngineEventAskFirstTests.swift` and `EngineEventAskHeldTests.swift`, with `EngineHarness` and `FakeClock`):
1. A Welcome back pop-up is open at the event start. The event pop-up shows at once. Answer it. Welcome back shows again.
2. A switch "What now?" is open at the start. The event pop-up replaces it, and "What now?" comes back after.
3. A To-do due prompt is open. The event pop-up replaces it, and the to-dos come back after.
4. A time block runs at the start. The event pop-up shows, and the time block keeps running.
5. A pause or a buddy session runs at the start. The event pop-up shows.
6. "Log and tell" mode with a time block running: the ask pop-up shows, and no activity is logged by itself.
7. Away at the start: no pop-up. Back before the event ends: the pop-up shows. Back after the event ends: no pop-up.
8. The user dismisses or logs the event while it waits. No pop-up shows.
9. 2 events start 5 minutes apart. The later one shows, and the earlier one asks after, if it is still on.
10. Regression: when nothing blocks the event, the pop-up shows at the start as today.

**Files:** `Engine+TrackerCalendarTick.swift` (123 lines; if it goes above 200, split the held-prompt part into a new `Engine+TrackerEventFirst.swift`), the runtime type that holds `pendingAsk` (add `heldPrompt`), and `business-logic.md`. `heldPrompt` is runtime only; nothing new is saved to disk.

**Performance:** no new timer. The check runs inside the current tracker tick.

---

## Track B: Calendar redesign (design H2)

**Goal:** in the hourly Week and Day grid, every event, activity, and to-do shows a title you can read. Plan, actual, and to-do each look different. Hover shows the details.

### B0. Rules and spec first
- This file is the spec.
- Rewrite `business-logic.md`, Calendar page rules 5, 5a, 12, and 15, to match B1–B7.
- Add a "Phase 24" entry to `docs/ROADMAP.md`.

### B1. Color fix: no more "all green"
- `Sources/SathiUI/Features/Calendar/CalendarBlockLook.swift:20-21`: a `.joined(category)` block uses its category color, the same as `.activity`. Remove `Night.calendarJoinedFill` and `Night.calendarJoinedText` (`Night+Calendar.swift:5-6`) when nothing else uses them.
- A joined activity shows a small link icon after its title (SF Symbol `link`).
- Tests: `CalendarBlockViewTests`. A joined block has its category fill, not green, and shows the link icon.

### B2. Core layout (`SathiCore/CalendarPage`), display only
Split the layout into 3 files, so that each file has 1 job and stays under 200 lines:

1. **`CalendarBlockHost.swift` (new).** An activity becomes a child of an event when both are true:
   - the activity starts no earlier than the event start − `Limits.calendarHostLeadMinutes` (5), and
   - the overlap is at least `Limits.calendarHostShare` (0.5) of the activity length.

   Each activity gets 1 host at most: the first event that matches. A child never takes a lane.
2. **`CalendarBlockLayout.swift` (rewrite).** Away stays a backdrop.
   - Top blocks that start less than `Limits.calendarSideBySideMinutes` (15 → **30**) after an open group's start join that group side by side. A group has no more than `Limits.calendarLanesMax` (2) lanes. More blocks become 1 "+N" chip.
   - A block that starts later and overlaps an open block sits on top at depth + 1.
   - `Limits.calendarCascadeMaxDepth` changes from 3 to **2**.
3. **`CalendarBlockNudge.swift` (new).** Input: a minimum display length in minutes (the UI gives the minimum height ÷ hour height × 60). The code makes each block at least that tall. When the block below in the same depth and lane would now overlap it, that block moves down. A host grows to hold its children below its title row.

`CalendarPlacedBlock` gets these new fields:
- `displaySpan` (the moved and grown time),
- `hostID: String?`,
- `children: [CalendarPlacedBlock]`,
- `isRaised`,
- `hiddenCount` (for "+N").

The real time stays in `span`, for hover and for edits.

**Tests** (update `CalendarBlockLayoutTests` and `CalendarBlockLayoutOverlapTests`; add `CalendarBlockHostTests` and `CalendarBlockNudgeTests`):
- Host: a 22-minute activity inside a 30-minute event is a child.
- Host: an 82-minute activity with a 30-minute overlap is not a child.
- Side by side: blocks that start 23 minutes apart share 2 lanes. Blocks that start 4 hours apart give 1 full-width block with 1 raised block on top (the Tue 1 PM and 5 PM case).
- A 3rd block in the same group becomes "+1".
- Nudge: 8-minute blocks back to back get the minimum height, and the next block moves down. A gap absorbs the move.
- A host with 2 children grows to fit them.
- Away never moves and never takes a lane.
- Blocks that only touch do not overlap.

### B3. Block views (`SathiUI/Features/Calendar`)
- **Event card** (`CalendarBlockView`, split into `CalendarEventCard.swift` and `CalendarActivityBlock.swift`):
  - outline in the calendar color, dark fill, `calendar` icon,
  - title that wraps to 1–3 lines, as the height allows,
  - short time on 1 line, "5:00 – 6:30 PM" (a new `Fmt.shortRange` in Core, with a test),
  - a host shows its title row, then its children inside.
- **Activity block:** solid fill (category color mixed on the page color, so it is not see-through), no outline, no icon.
  - A short block shows its length on the right ("8 m").
  - A tall block shows the time range below the title.
- **Raised block:** a 2 pt ring in the page color. No shadow. Do not add card shadows back.
- **Sizes** (`UIMetrics+CalendarPage.swift`):
  - `calendarBlockFont` 11 → 12, `calendarBlockTimeFont` 10 → 10.5,
  - `calendarHourHeight` 48 → 60,
  - `calendarCascadeIndent` 26 → 14,
  - new `calendarBlockMinTextHeight` = 26, `calendarEventRadius` = 8, `calendarTitleLinesMax` = 3.
- **Away in Week:** stripes only, with no label. Day keeps the "Away" pill. In both views, the hover card has "Edit Away".
- **Tests** (`CalendarBlockViewTests` and the new `CalendarEventCardTests`):
  - An event has an icon and an outline. An activity has neither.
  - A short block shows "8 m".
  - A host lists its children.
  - Raised blocks have the ring.

### B4. To-do pill
- `CalendarTodoChip.swift` becomes a pill:
  - 22 pt tall, round ends, list-color outline,
  - a tick circle, the 12 pt title, and the due time,
  - on the right side of the column, drawn above the blocks.
- New `CalendarTodoDueLine.swift`: a dashed line across the column at the due time, in the list color. It never takes clicks.
- A click on the tick marks the to-do done, as today. A click on the body opens the edit popover, as today.
- Sizes (`UIMetrics+TodoCalendar.swift`): `calendarChipHeight` 18 → 22, `calendarChipFont` 10 → 12, and a new `calendarTodoLineDash`.
- Tests: `CalendarTodoChipTests`. The pill shows the title and the due time, the line exists, and the tick still marks the to-do done.

### B5. Hover card
- **Core:** a new `CalendarPage/CalendarHoverInfo.swift`, built from a block. It holds:
  - the kind ("Calendar event · Plan", "Activity · Actual", "To-do · Apple Reminders", "Away"),
  - the title, the time range, and the length,
  - the meta line (calendar name and "in 2 calendars", the category, the list, or the Away reason),
  - the children ("Done in this event"),
  - the actions.

  Put the strings in a new `Copywriter+CalendarHover.swift`.
- **Actions:**

  | Kind | Actions |
  |---|---|
  | Event | Start as activity, Edit, Open in Calendar |
  | Read-only event | Start as activity, Open in Calendar |
  | Activity | Edit, Merge, Delete |
  | To-do | Mark done, Edit, Open in Reminders |
  | Away | Edit Away |

- **"Start as activity":** a new Engine API, `startActivity(fromEvent:)`, in a new `Engine+CalendarPageStart.swift`. It runs the same path as `logEvent` (`Engine+TrackerCalendarTick.swift:14-38`), so the activity gets the event title and `sourceEventID`. It also clears `pendingAsk` for that event. This links Track A and Track B.
- **UI:** a new `CalendarHoverCard.swift` (the card) and `CalendarHoverHost.swift`.
  - `.onHover` opens the card after `Timing.calendarHoverOpenDelay` (0.35 s), with one `Task.sleep` and no repeating timer.
  - The card closes `Timing.calendarHoverCloseDelay` (0.2 s) after the pointer leaves the block and the card.
  - The card opens on the right side of the block. For Wed to Fri it opens on the left side.
  - The hovered block gets a white ring.
  - A click keeps its current job (edit panel or popover). ⌘-click keeps Merge.
- **Tests:**
  - `CalendarHoverInfoTests` (Core): every kind gives the right text and actions, a read-only event has no Edit, and a host lists its children.
  - `EngineCalendarStartFromEventTests`: the activity has the event title and `sourceEventID`, and `pendingAsk` is cleared.
  - `CalendarHoverCardTests` (UI): the buttons call the right Engine actions.

### B6. Week defaults
- Hide the side panel by default in Week: a new saved `prefs.calendarPage.sidePanelShownWeek` (default false, lenient decode). Day and Month keep `sidePanelShown`. Use the `/data-migration` skill.
- Row zoom keeps working: "1 h", "30 min", and "15 min" multiply the new 60 pt hour height.

### B7. Day view
- Day uses the same layout, cards, to-do pills, and hover card. Day keeps the Away pill and the Merge strip.
- Test: `CalendarPageGridTests`. Day and Week use the same placed blocks for the same data.

### B8. Docs and website
- Update the `CLAUDE.md` module map with the new files, and update the Calendar paragraph.
- Update the README.
- **Later (not in this phase):** run `/sathi-website` for the Calendar screenshots.

### Constants summary

| Constant | File | Value |
|---|---|---|
| `calendarSideBySideMinutes` | `Limits+CalendarPage.swift` | 15 → 30 |
| `calendarCascadeMaxDepth` | `Limits+CalendarPage.swift` | 3 → 2 |
| `calendarLanesMax` | `Limits+CalendarPage.swift` | new, 2 |
| `calendarHostLeadMinutes` | `Limits+CalendarPage.swift` | new, 5 |
| `calendarHostShare` | `Limits+CalendarPage.swift` | new, 0.5 |
| `calendarHoverOpenDelay` | `Timing.swift` | new, 0.35 s |
| `calendarHoverCloseDelay` | `Timing.swift` | new, 0.2 s |
| Block fonts, hour height, indent, minimum height, radius, line count | `UIMetrics+CalendarPage.swift` | see B3 |
| Chip height and font, line dash | `UIMetrics+TodoCalendar.swift` | see B4 |

### Performance
- No repeating timer. Hover uses one-shot `Task.sleep` and cancels it when the pointer leaves.
- The layout runs only when the blocks or the range change (no work per frame). Keep the result cached in the view model.
- There is no new `@Published` state in Engine. The hover state is `@State` in the view.
- Run `./build.sh --install` and `./scripts/perf.sh`. The user runs `./scripts/perf.sh --windows` in Terminal.

### Risks
1. When short blocks move down, they show up to a few minutes after their real time. Hover always shows the real time.
2. 60 pt rows make the week scroll more: 6 AM to 6 AM is 1,440 pt.
3. A hover card over a block can hide the next block for a short time. The open delay limits this.
4. The `CalendarBlockLayout` rewrite touches 2 test files that exist. Their expected values change, and the rules in B0 support the change.

---

## Decisions (answered 2026-11-18)

1. **Q1. Event pop-up priority:** calendar events come first. The event ask shows at once, on top of other pop-ups and during a busy state. Only Away and a full-screen lock make it wait. "Log and tell" never logs by itself when the tracker is busy or another pop-up is open; it asks. See Track A.
2. **Q2. Side panel in Week:** a separate saved choice for each view. Week defaults to hidden (new `sidePanelShownWeek`, default false; use the `/data-migration` skill). Day and Month keep `sidePanelShown`.
3. **Q3. Hour height:** 60 pt in all views.

---

## Checklist

**Track A: event pop-up fix**
- [ ] Rule text updated in `business-logic.md` (tracker rules 2 and 7)
- [ ] `EngineEventAskHeldTests` written and red for the right reason
- [ ] `Engine+TrackerCalendarTick.swift` fixed: held ask, busy hold, ask while still on
- [ ] Q1 done: event ask on top, held prompt comes back, busy states ask, Away and lock wait
- [ ] `./scripts/test.sh`, `./scripts/lint.sh`, and `swift build -c release` pass
- [ ] `code-reviewer` agent run, blockers fixed
- [ ] Hand test: open "What now?" before a test event starts; the event pop-up replaces it at the start, and "What now?" comes back after
- [ ] Commit on the branch, then ask before merging to `main`

**Track B: calendar redesign**
- [ ] B0 rule updates and ROADMAP entry
- [ ] B1 color fix and link icon, with tests
- [ ] B2 host, layout, and nudge in Core, with tests (all files under 200 lines)
- [ ] B3 event card, activity block, sizes, and Away label rule, with tests
- [ ] B4 to-do pill and due line, with tests
- [ ] B5 hover card, `startActivity(fromEvent:)`, and `CalendarHoverInfo`, with tests
- [ ] B6 `sidePanelShownWeek` (default false) with the `/data-migration` skill
- [ ] B7 Day view uses the same pieces, with a test
- [ ] Q3: 60 pt hour height in all views
- [ ] `./scripts/test.sh`, `./scripts/lint.sh`, and `swift build -c release` pass with no new warnings
- [ ] `./build.sh --install` and `./scripts/perf.sh` pass
- [ ] The user runs `./scripts/perf.sh --windows` in Terminal
- [ ] `ui-verifier` agent: the real app against board H2
- [ ] Hand tests: hover each kind, "Start as activity", the Tue 1 PM/5 PM case, short blocks, to-do tick, ⌘-click Merge, row zoom
- [ ] `code-reviewer` agent run, blockers fixed
- [ ] `CLAUDE.md` module map and README done
- [ ] Commit on the branch, then ask before merging to `main` and before any push
- [ ] Later: `/sathi-website` screenshots
