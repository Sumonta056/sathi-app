# Phase 25: Calendar Day and Week, Plan | Actual

Status: design approved on 2026-11-18. Not started.

Design (approved, real data 14–20 Nov 2026): https://claude.ai/artifact/QpmNuNugfzU3GCvNQRG79d

Earlier steps, already on `main` (3acb272): phase 24 Track A and Track B, then option A (group short runs, trim, narrow-lane chip) and the covered-block fixes. This phase replaces the Day and Week grid look of phase 24 and option A. Month does not change.

## Why

On busy days the phase 24 grid moved short blocks far from their real time and drew blocks over each other. The user wants to see plan (calendar events) next to actual (activities), with every item at its real time, every title readable, and every number exact.

## Decisions (answered 2026-11-18)

1. Day and Week split each day into **Actual** (activities, left, 60 %) and **Plan** (calendar events, right, 40 %).
2. The Calendar page has **no Merge**: no checkboxes, no ⌘-click selection, no Merge strip, no Merge button in the hover card. Merge stays on the Activities page.
3. Every item is **one block from its real start to its real end**, also across hour rows.
4. Overlap: **side by side only when 2 items start less than 30 min apart**. Otherwise the later item is **raised** on top. The earlier item keeps full width.
5. Every **Away** row shows as a normal dim block, also when it is shorter than 5 min. Items are in strict start-time order.
6. Week has a **day count**: 3, 4, 5 or 7 days.
7. **Exact numbers**: round each start and end to the nearest minute once. Length = rounded end − rounded start. Use the same values in cards, hover cards, and tests.
8. Rejected, do not build: Plan | Actual narrow sub-columns at 7 days with option A, the list without time positions, continuation tints and "↳ until" labels, "+N away" folds, side bars.

## B1. Layout core (`SathiCore/CalendarPage`)

The "elastic hour" layout, display only, pure, cached in the page data (as `placed` is today).

- **Rows.** One row for each Row zoom step (`rowMinutes` 60, 30, or 15; default 60). Base scale: 1 pt per minute (`UIMetrics.calendarHourHeight` 60 pt per hour). Week: all shown days share the row heights.
- **Position.** A block's top = the y of its real start. Its bottom = max(top + minimum height, y of its real end).
- **Minimum height** (text must fit): Day card 46 pt, Day Away card 40 pt, Week block 34 pt, Week narrow block 22 pt.
- **Push.** When a block would overlap a block above it that does **not** overlap it in real time and shares horizontal space, it moves down just enough (gap 2 pt in Week, 4 pt in Day). A block never moves up.
- **Row growth.** A row grows only so that each block's title (22 pt) starts inside the row where the block starts. The scale inside a row stays fixed. The extra space goes at the end of the row. A block never moves into the next row.
- **Lanes, inside one half (Actual or Plan) of one day:**
  - Items that overlap in real time and start less than `Limits.calendarSideBySideMinutes` (30) apart sit side by side: 2 lanes at most (`calendarLanesMax`), half width each. A third one goes into a "+N" badge on the first lane. The hover card lists it.
  - An item that starts 30 min or more after an item it overlaps is **raised**: depth + 1, moved right by `UIMetrics.calendarCascadeIndent` (14 pt), a 2 pt ring in the page color (`#121826`), no shadow. Depth stops at `calendarCascadeMaxDepth` (2). A deeper item goes into "+N".
  - Items that do not overlap in real time never share a lane width.
- **Night fold (Week).** A run of 2 or more rows where every shown day has only Away or nothing becomes one 22 pt striped strip ("7:00 – 9:00 AM · away or nothing on every shown day"). A row that a non-Away block crosses never folds. A run that reaches the end of the grid (6 AM) and does not start at 6 AM is not drawn: its rows are removed and the grid ends at the last open row (no strip at the bottom). The row that holds now never folds (the layout takes `now`).
- **"Done during".** An activity is done during an event when it starts no earlier than the event start − 5 min (`calendarHostLeadMinutes`) and at least half of it is inside the event (`calendarHostShare` 0.5).
- **Which events are Plan.** Every shown calendar event, except the events that Sathi wrote for a tracked activity (the activity's `eventID`): those are the activity itself and do not show as plan. An event the user started an activity from (`sourceEventID`) shows in Plan, and the activity shows in Actual with the "done during" link.

Remove what this phase replaces, in the same wave: host and child nesting, option A grouping (`CalendarBlockRuns`, `CalendarBlockGroup`, trim), the narrow-lane chip and `CalendarNarrowLanes`/`CalendarColumnWidth`/`CalendarLaneMemory`, and the old nudge. Keep only what the new layout uses. Update or delete their tests.

## B2. Day view

- The page opens on Day (the page day that holds now) when no date is given; a Month date click opens that date. Row zoom default stays 1 h; saved prefs are kept.
- Header: "Actual · 6h 31m" (tracked time, no Away) and "Plan · 3 events".
- Left time rail with hour labels, a line at each hour, a dashed line every 15 min.
- **Activity card** (Activities row style): 3 pt left edge in the category color, fill = category color mixed on the card color, bold title (wraps up to 3 lines when tall), time "10:38 AM – 12:31 PM", category name in its color, "Calendar" or "Not in calendar" tag, length on the right ("1h 53m"), edit pencil. Away card: dim, stripes, title "Away · Sleep", time and length.
- **Event card**: outline in the calendar color, card fill, calendar icon, title (up to 3 lines), time, calendar name (dark colors made lighter for text only), "N done during" tag, length on the right. Hover shows "Start as activity" and Open.
- A 26 pt gutter between the halves holds the "done during" link: a line in the event's color from the activity to its event, with a dot on the activity. When the event is in a "+N", the link goes to the card that holds it. The gutter has a solid `Night.divider` line at the end of the Actual half and a dashed line at the start of the Plan half, both full grid height, drawn under the link lines.
- No "Free" rows: empty time is empty space.
- Every Day card always shows all its fields: title, time range, category (or calendar name), tag, and length. A card never drops the time or the length because it is short; the minimum height (46 pt) makes them fit. The old phase 24 look (full-width flat blocks, time on tall blocks only, length on short blocks only) must not remain anywhere in Day.

## B3. Week view

- **Day count** menu button in the header: it shows the current count ("7 days" and a chevron) and opens a menu with 3, 4, 5 and 7 days; a pick saves the count and resets the range. The Week header stays on 1 row like Day (title left, summary in the middle, controls right); below the 1-row width it may wrap, as Day does. New saved pref `calendarPage.weekDays` (3, 4, 5 or 7; default 7; lenient decode, an unknown value gives 7). Use the `/data-migration` skill.
- Range: 7 days keeps the Saturday-start week. 3, 4, 5 days put today in the middle, leaning to the past: 3 = 1 day back and 1 ahead, 4 = 2 back and 1 ahead, 5 = 2 back and 2 ahead. ‹ › moves by N days. "Today" goes back to the default range.
- Day header "Mon 16 Nov", then "ACTUAL | PLAN" labels.
- Blocks: title (up to 3 lines when tall) and "2:36 – 3:02 PM · 26m". Away: dim block with stripes. "Done during": a small dot in the event's color on the activity.
- **Narrow mode** when Actual would be under 120 pt (7 days on a normal window): one-line blocks with start time and title, 22 pt minimum, 2 lines only when the block is at least 34 pt tall. Hover gives the full card.
- Row zoom 1 h / 30 min / 15 min works as today.

## B4. Hover card and actions

Keep the phase 24 hover card (open 0.35 s, close 0.2 s, one `Task.sleep`, right side, left for Wed to Fri, white ring on the hovered block), with these changes:
- No Merge action anywhere. Activity: Edit, Delete. Event: Start as activity (only when the tracker is on and the event is on now or starts within 5 min), Edit (writable events only), Open in Calendar. Away: Edit Away. To-do: Mark done, Edit, Open in Reminders.
- A block with "+N" lists the hidden items under "Also here"; a click on a row does what a click on that item does.
- Times and lengths in the card use the rounded-once values.

## B5. To-dos (answered 2026-11-18: option A, mockup https://claude.ai/artifact/5qcmvor46ZBi7F6sQ2B3ub)

Approved: a to-do with a due time shows in the **Plan** half as the phase 24 pill on its dashed due line; a date-only to-do stays in the all-day row.  The pill takes no lane and never moves a block.

## Rules first

Before code, rewrite `.claude/rules/business-logic.md` Calendar page rules 5, 5a, 5b, 11, 12 and 15 to match this spec (Merge removed from the Calendar page, the split, the layout, the day count). Add a "Phase 25" entry to `docs/ROADMAP.md`.

## Tests (write first, red for the right reason)

Use `Tests/SathiCoreTests/CalendarPage/CalendarRealWeekFixtures.swift` (real 14–20 Nov rows) and `CalendarOverlapCheck.swift`; add the real events below as fixtures.
- Layout: top and bottom = real start and end except pushes; no two blocks overlap; every pushed block sits exactly one gap under a block that shares horizontal space and does not overlap it in real time; no block moves up or into the next row; each title starts inside its start row.
- Lanes: start < 30 min apart gives 2 lanes; ≥ 30 min gives raised depth 1 with full-width parent; 3rd → "+N"; depth > 2 → "+N".
- Tue 17 Plan: "Bangladesh Bank AI Professional Class" 1:00–5:30 full width; "CCAR-F Exam Preparation Workshop" 5:00–6:30 raised.
- Wed 18 Plan: "Friday Java Brief" 10:06–10:36 and "Frontline Morning Scrum" 10:30–11:00 side by side at their real times.
- Rounding: 14:35:54–15:01:32 shows "2:36 – 3:02 PM · 26m".
- Sathi-written events are not in Plan; a `sourceEventID` event is.
- Night fold rules. Day count range math for 3, 4, 5, 7 and ‹ ›. `weekDays` lenient decode and round trip.
- UI (ViewInspector): Day card fields; Week narrow mode; no Merge control or action anywhere on the page; hover actions per kind.

Real events for fixtures (from macOS Calendar, 14–20 Nov 2026, Asia/Dhaka):
- Sun 15: Air Ticket 9:00–9:30 PM.
- Mon 16: Thomas Message! 10:30–11:00 (Office Work); Personal Editorial Scrum 1:00–1:30 PM; Personal Editorial scrum 1:00–1:25 PM; CCAR-F Workshop Discussion (Domain 2) 4:30–5:00 PM; Claude update - What is new and the way forward 6:30–6:55 PM.
- Tue 17: Bangladesh Bank AI Professional Class 1:00–5:30 PM; CCAR-F Exam Preparation Workshop 5:00–6:30 PM.
- Wed 18: Friday Java Brief 10:06–10:36 (Learning); Frontline Morning Scrum 10:30–11:00; Personal Editorial scrum 1:00–1:25 PM.
- Thu 19: Vue & Nuxt Friday Brief 10:00–10:30; Frontline Morning Scrum 10:30–11:00; Personal Editorial scrum 1:00–1:25 PM.
- Fri 20: Agentic Daily 13 Nov 2026 10:15–10:45; Personal Editorial scrum 3:00–3:25 PM; CCAR-F Exam Preparation Workshop 5:00–6:30 PM.

## Constants

| Constant | File | Value |
|---|---|---|
| Day card minimum height | `UIMetrics+CalendarPage` | 46 pt (Away 40 pt) |
| Week block minimum height | `UIMetrics+CalendarPage` | 34 pt (narrow 22 pt) |
| Block gap | `UIMetrics+CalendarPage` | Week 2 pt, Day 4 pt |
| Title room in start row | `UIMetrics+CalendarPage` | 22 pt |
| Night fold strip | `UIMetrics+CalendarPage` | 22 pt; fold run ≥ 2 rows (`Limits`) |
| Actual share | `UIMetrics+CalendarPage` | 0.6 |
| Narrow mode below | `UIMetrics+CalendarPage` | Actual 120 pt |
| Day link gutter | `UIMetrics+CalendarPage` | 26 pt |
| Week day counts | `Limits+CalendarPage` | [3, 4, 5, 7], default 7 |
| Side by side, lanes, cascade, host lead and share | `Limits+CalendarPage` | keep 30 min, 2, 2, 5 min, 0.5 |

## Performance

No new timer. The layout runs in Core when the blocks, the range, the day count, or the row zoom change, and the page data caches it. Hover state stays `@State` in the view. Run `./build.sh --install` and `./scripts/perf.sh`; the user runs `./scripts/perf.sh --windows`.

## Risks

1. Busy runs of short items push later items down (Mon 16, 3 PM: up to about 143 pt). Each block still shows its real time and its bottom is exact.
2. Busy hours make Week tall (4 days, 1 h rows: about 1,640 pt).
3. 7-day narrow mode shows only short titles; hover gives the details.

## Checklist

- [ ] Rules and ROADMAP updated
- [x] B5 to-do question answered by the user (option A)
- [ ] B1 layout core with tests; replaced code removed
- [ ] B2 Day view with tests
- [ ] B3 Week view and `weekDays` pref with tests
- [ ] B4 hover card without Merge
- [ ] `./scripts/test.sh`, `./scripts/lint.sh`, `swift build -c release` pass
- [ ] `code-reviewer` run, blockers fixed
- [ ] `./build.sh --install`, `./scripts/perf.sh`; user runs `--windows`
- [ ] `ui-verifier` against the approved mockup
- [ ] `CLAUDE.md` module map and README updated
- [ ] Ask before merge to `main` and before push
