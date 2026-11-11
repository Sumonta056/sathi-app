# Phase 19 — Main window v2 (Activities, Reports, Today, Sidebar)

Approved by the user on 2026-11-11. The mockups are the visual source of truth:
`docs/design/phase-19/*.dc.html` (open in a browser; Night colors, Figtree font).

## Global rules

- Use the Night tokens (`NightPalette.swift`) and existing components. New sizes go in new
  `UIMetrics+<Area>.swift` files. New words go in new `Copywriter+<Area>.swift` files.
- Every choice chip is a square box (corner radius 6). No round pills. No card shadows.
- No dropdown menus for choices: show the choices as visible chips.
- One job per file, max 200 lines, no comments, no magic numbers (see CLAUDE.md).
- Tests first: Swift Testing for Core, ViewInspector for views.

## S1. Category table card (shared by Activities, Reports "All buddies", Today "Breakdown")

Mockup: top-left card of `Activities.dc.html`, Breakdown card of `Today.dc.html`,
"Time by category" card of `ReportsAll.dc.html`.

- Header: big total ("12h 37m") and a muted line ("logged · 10 categories").
- One 100% stacked bar, one segment per category, in category color, in table order.
- A table of every category: color square, name, hours (bold), percent (muted).
  Two columns when the card is wide (Activities, Today), one column in Reports.
  Rows sorted by time, largest first. Thin divider between rows. Names never wrap.
- Percent = round(category seconds / total seconds × 100). A category above 0 seconds
  that rounds to 0 shows "<1%".
- Optional change column (Reports only): "+40m", "−12m", "0m" against the range before.
- The Away category (Reports week view) uses the away color and sorts like any other row.

## S2. Activities page (Day range)

Mockup: `Activities.dc.html` (edit closed) — press a pencil to see the edit section open.

1. Top row: S1 card takes 2/3 of the width; the right 1/3 holds 4 tiles in a 2×2 grid:
   Total logged (+ change vs the range before), Focus work (+ "% of the day"),
   Away (+ "N times · <top place>"), Activities (+ "Top: <category>"). Use data that
   exists; a tile with no data shows "—".
2. Timeline card: header "Timeline", count line ("18 activities · 1 gap"), "+ Add activity".
   Under it the day lane (existing ribbon) and its hour axis.
3. Timeline list: one row per activity, in time order.
   - Left column: start time ("7:00 AM").
   - Card: tinted fill in the category color, 4 pt color bar on the left edge.
   - Line 1: the full title on one line, truncated with "…".
   - Line 2: time range ("10:37 AM – 12:42 PM"), category name in its color, and the
     calendar name with a calendar icon when the activity is saved to a calendar.
   - Right: duration in bold, then a pencil icon button (no "Edit" text). Accessibility
     label "Edit <title>".
   - Height is NOT to scale: 44 pt for an activity under 1 hour, 60 pt for 1–2 hours,
     68 pt for more than 2 hours. (Use constants.)
   - A gap with nothing logged inside tracker hours shows a dashed row
     "Not logged · <range>", its length, and a "+" button that opens the add form for that span.
   - Away rows use the gray away color and show "Away · <place>".
4. Edit section: the pencil opens an edit section INSIDE the timeline card, to the right of the
   list (list keeps the remaining width). It is not a sheet, not a popover, not an overlay,
   and the page does not dim. The edited row gets a 2 pt outline in its category color.
   Fields, top to bottom:
   - Name text field.
   - Start, End (existing 5-minute TimeMenu chip grid), Length (read only, accent color).
   - Length chips 15m, 30m, 1h, 2h: each sets End = Start + that length.
   - Category: every category as a visible chip + "None". Away rows show the place chips instead.
   - Calendar: chips "Do not add" + each calendar the tracker can write to. The chip of the
     activity's current calendar is selected.
   - Footer: Delete (left), Cancel, Save. Save shows the existing error text on failure.
   Only one edit section is open at a time. Cancel or Save closes it.
5. Week and Month ranges keep their current list views but use the S1 card on top.

## S3. Calendar choice on edit (Core)

- `ActivityEdit` gains the calendar choice for the activity (none, or a calendar id).
- Save moves the activity's calendar event: none → delete the event; a different calendar →
  delete the old event and write a new one in the chosen calendar; same → update as today.
- Update `.claude/rules/business-logic.md` first. No saved-data shape change beyond what
  `Activity.calendarID` already stores.

## S4. Reports page (Week/Day/Month)

Mockups: `ReportsAll.dc.html`, `ReportsBuddy.dc.html`, `StreakOverview.dc.html`.

1. A tab row under the header: "All buddies", then one tab per buddy showing
   "<Name> · <goal days>/<days in range>" in the buddy color. Selected tab: 2 pt border.
2. "All buddies" tab:
   - Score card: ring with goals met / goals possible ("11 of 28 goals"), the label
     "WEEK SCORE · N DAYS SO FAR", a one-line headline from Copywriter (names the best and the
     weakest buddy), a change line vs the range before + streak, and 4 small rings (one per
     buddy, "4/7").
   - "Day by day" grid: one row per buddy, one column per day. Cell shows the day value
     (glasses or minutes, "Off" on a day off). Solid buddy color = goal met; dim tint = some
     progress; dashed outline = future. A legend line under it. A buddy name opens its tab.
   - Bottom row: S1 card (one column, with change column, includes Away) on the left; the streak
     overview calendar (S5a) on the right (440 pt).
3. Buddy tab: big bar chart for that buddy with the goal line and value labels, a facts column
   (this range total + change, goal days, best day, daily average, streak), and under it the
   buddy month calendar (S5b). Fix the current overlap bug: nothing may draw under the tabs.

## S5. Streak calendars (month view with day numbers)

Monday first. Leading blanks for the first week. Arrows for the month before / after
(after is disabled for the current month). Today has a white ring.

- S5a overview (All buddies): each day cell shows the day number and 4 dots (Fota, Boi,
  Shanti, Shokti) — a dot is in the buddy color when that buddy met its goal, gray when not.
  A day where every on-buddy met its goal (a streak day) has a green tint and green frame.
  Header: "November 2026" and "Streak N days". Legend under the grid.
- S5b buddy calendar: day number inside a cell filled in the buddy color when the goal was met,
  a dark buddy tint when there was some progress, gray when none, outline for future days.

## S6. Today page cards

Mockup: `Today.dc.html`.

1. Card 1, full width: "Today so far", total ("12h 37m"), "logged · N% of tracker hours",
   the ribbon with a "Now" marker, and the hour axis.
2. Row 2: left (1.7 parts) S1 card titled "Breakdown" with the 100% bar and the 2-column table;
   right (1 part) "Coming up": rows with a tinted icon tile, title, time (+ detail), and an
   "in N min" badge in the row's color. Both cards have the same height. No empty space.

## S7. Sidebar

Mockup: `Sidebar.dc.html`.

1. Logo row: logo, "Sathi", and an open/close button (sidebar icon). Closed = a 64 pt icon
   rail; open = the current width. The open/closed state is kept between launches.
2. Pages: Today, Activities, Reports with icons.
3. "SETTINGS" section label, then every settings page, ALWAYS visible (no expand/collapse):
   General, Fota · water, Boi · reading, Shanti · calm, Shokti · gym, Quick reminders,
   Activity tracker, Time blocks, Sound. Each has an icon on a small tile tinted in its color
   (buddy colors; quick = quick pink, tracker = tracker coral, time blocks = block teal,
   general/sound = neutral).
4. Bottom: the existing Tracker status block, then a one-line footer:
   "Sathi <version> · by Sumonta", GitHub icon link, portfolio (globe) icon link.
5. Closed rail: logo, open button, page icons, a divider, settings icon tiles (selected one
   outlined), and at the bottom a tracker dot (coral when on), the GitHub icon, and the version.
   Every icon has a tooltip and an accessibility label.
