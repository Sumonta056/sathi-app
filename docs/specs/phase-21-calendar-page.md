# Phase 21: Calendar page and manual merge

Goal: one page that shows the plan (calendar events) and the actual day (activities) on one time grid, so the user does not need Apple Calendar to look at the day. Plus a manual merge for activities that Sathi did not merge by itself.

Integration branch: `feat/calendar-page` (worktree `../Sathi-calendar`).
Design reference: Design canvas "Sathi Calendar page" (boards "A · Week, one column", "Month", "New event popover", "Day · real data"). Week uses layout A, not B.
Terms: see `GLOSSARY.md` (Calendar page, Calendar event, Shown calendars, Activity, Away).

Two tracks:
- Track 1: the Calendar page (experimental, off by default).
- Track 2: manual merge (not experimental; Activities page and, after the tracks merge, the Calendar page).

## Track 1: Calendar page

### C1. Place and switch
1. New sidebar page "Calendar" in the main window. The sidebar item and the rail icon have no tag; the word "experimental" shows only in the Settings switch (C1.2).
2. Settings has a switch "Calendar page (experimental)". Default off. Off: the sidebar has no Calendar item. On: the item shows after Activities.
3. The page works when the activity tracker is off. Then it shows only events.
4. The page needs only calendar access. Not asked: the page shows "Allow calendar access" (asks macOS). Denied: "Open System Settings". This reuses the access states that Sathi already has.
5. The Activities and Reports pages do not change (except the Merge button of Track 2).

### C2. Views
1. A segment control: Day, Week, Month. Buttons ‹, Today, ›. ‹ and › move by 1 day, 1 week, or 1 month.
2. Day and Week: one time grid. Week has 7 columns from Saturday (`Limits.calendarPageFirstWeekday` = 7, Gregorian), whatever the region, like the user's Apple Calendar. Reports and Activities ranges keep the region's first weekday. The page opens on Week (the week that holds now); a click on a Month date opens that date in Day.
3. Week layout A: events and activities share one column. Blocks that overlap in time split the column width side by side.
4. The grid has 24 rows of 1 hour, from the 6 AM row to the 5 AM row of the next date, and it scrolls vertically (no scroll bar). Day and Week have a "Row" zoom in the header: "1 h" (base hour height), "30 min" (× 2, a faint half-hour line), "15 min" (× 4, faint lines every 15 min). Saved in `prefs.calendarPage.rowMinutes` (60/30/15, default 60, a bad value gives 60). Month ignores it. Slot clicks still round down to 15 min at every zoom.
5. Calendar-page day: a day column and its totals cover 6:00 AM of that date to 6:00 AM of the next date (`Limits.calendarPageDayStartHour` = 6, a constant, not a setting). The page shows "6 AM to 6 AM" near the totals (removed in phase 25 on 2026-11-19: the header has no such note). Example: a row from 12:22 AM to 2:02 AM on Thursday shows at the bottom of the Wednesday column. Activities and Reports keep midnight.
6. On open, the grid scrolls to the current time for a range that holds now, else to the 6 AM row.
7. A red line marks the current time in a column for today. (Phase 25, 2026-11-19: the time pill is in the hour gutter, not on the line.)
8. All-day events show in a row at the top of Day and Week. They are read-only.
9. Month: a grid of weeks, each row from Saturday as in C2.2. Each date cell shows its event chips (max `Limits.calendarMonthChipsShown`, then "+{n} more") and the tracked time of that calendar-page day. A click on a date opens the Day view of that date. Today has a highlight.
10. A block shows title, and the time range when the block is tall enough. Very short blocks (less than the minimum height) show as a thin block without text.

### C3. What shows, and no duplicates
1. Events: from every calendar in the "Shown calendars" list (C4). Activities: from the activity store, all kinds (work, event, buddy, time block, Away).
2. One block for one thing. An activity that has an `eventID` (Sathi wrote the event) or a `sourceEventID` (Sathi logged it from that event) hides that event. The page shows only the activity block.
3. Two events with different IDs both show, also when the titles are almost the same (twin events from 2 calendars).
4. Style: an event that has no activity is an outline in the color of its calendar. An activity is a filled block in the color of its category. Away is grey. An activity that came from an event (`sourceEventID`) has the "joined" fill (green family).
5. Week and Month only: rows with the same text (trimmed, case-sensitive) and the same category, with a gap of `Limits.calendarDisplayJoinGap` (5 min) or less, draw as one block. The Day view draws each row. This is a display rule only. Saved data does not change.

### C4. Shown calendars
1. A "Shown calendars" list on the page (side panel or menu) with one check box for each readable calendar, grouped by account.
2. All calendars are shown at first. A calendar that appears later is shown.
3. The list is saved in prefs (`calendarPage.hiddenCalendarIDs`, a set of hidden IDs; lenient decode, default empty; follow `/data-migration`).
4. It is separate from the tracker's ticked calendars. A change in one does not change the other.

### C5. Sync
1. Sathi reads events when the page opens, when the range changes, and when macOS posts `EKEventStoreChanged`. No repeating timer.
2. While the page is closed, the Calendar page does no work. The tracker listens to calendar changes on its own while it is on and ticks at least 1 calendar (also with the page closed); a change only marks its event cache stale and asks for a tick. The page part (calendar list, rebuild) runs only while the page is open. One observer at most, kept while the page or the tracker needs it.
   - Ruling R1 (updated): a page event write and any `EKEventStoreChanged` mark the tracker's event cache stale (`trackerCalendarRuntime.readAt = nil`). The tracker's event rules do not change. The page does its work only while it is open.
3. A change in Apple Calendar shows on an open page without user action.

### C6. Create and edit events
1. A click on an empty slot opens the "New event" popover with start at the slot (rounded down to 15 min) and end start + 30 min.
2. A click on an event opens the same popover with its values.
3. Fields: title, start, end (5-min time chip grid `TimeMenu`), calendar. Buttons: Save, Cancel, and Delete (edit only).
4. The calendar choice lists every calendar that macOS allows Sathi to write to (`allowsContentModifications`). Read-only calendars only show their events.
5. New event default calendar: the last calendar used on this page, else the macOS default, else the first writable one.
6. Repeating events and events with guests are read-only in Sathi. The popover shows the values and "Open in Calendar" only.
7. Save writes through the existing `CalendarWriter` (`save`, `update`, `delete`). A failed write shows an error line and keeps the popover open. Nothing is lost.
8. Title: trimmed, line breaks become spaces, max `Limits.blockTitleMax`. Empty title → Save is off. End must be after start.
9. A new event is a plan, not an activity. Sathi logs it only through the tracker rules (C7).
10. No drag to move or resize in this phase.
11. A click on an activity block opens the edit panel from the Activities page (same panel, same rules).

### C7. Sync with the tracker (required)
The tracker's event logic does not change. These tests prove that the Calendar page and the tracker agree:
1. An event that the user creates on the Calendar page, in a calendar that the tracker ticks, gives the tracker reaction at its start: the "eventAsk" prompt with `eventMode = .askFirst`, the log and 1-min note with `.logAndTell`.
2. An event that appears from outside (Apple Calendar, via the store change) shows on the page after the change notification, and gives the same reaction at its start.
3. An event that the user deletes, or moves to a later start, before its start gives no reaction at the old start. A moved event reacts at its new start.
4. Each of tests 1 to 3 runs with `.askFirst` and with `.logAndTell`.
5. An event in a calendar that the tracker does not tick shows on the page and gives no tracker reaction.
6. After the tracker logs the event, the page shows one block (the activity), not two.

### C8. Statistics
1. For the shown range: time tracked (work activities), time planned (events, all-day excluded, overlap counted once), and time by category.
2. Day, Week, and Month: a side panel, and a one-line summary in the top middle of the header ("Tracked 42 h 05 m · Planned 29 h 16 m", muted labels, bold values, never wraps). No line above the grid.
3. No "events joined" number in this phase.
4. A header button (icon `sidebar.right`, "Show side panel"/"Hide side panel") hides or shows the side panel. The grid takes the free width; the summary stays. Saved in `prefs.calendarPage.sidePanelShown` (default true; old prefs without it decode to true). The activity edit panel still opens while the side panel is hidden.

### C9. Performance
1. No repeating timer. The page redraws on a store change, a range change, or the current-time line (at most 1 time per minute, only while the page is visible).
2. Event reads only for the visible range.
3. `./scripts/perf.sh` passes.

## Track 2: Manual merge

### M1. Select and merge
1. The Activities page Day view lets the user select 2 or more activities of one calendar day (midnight to midnight) and press "Merge".
2. The merge is possible only when everything between the first and the last selected row is: other selected rows, empty time, or Away rows without a place. Sathi removes those Away rows.
3. A named Away (a row with an away place), a buddy session row, a time block row, or an event row (`kind == .event` or `sourceEventID`) between them, or in the selection, stops the merge. The button is then off and says why in one line.
4. Rows with different text can merge.
5. The merged row keeps the id, text, and category of the first row. Its start is the start of the first row, its end is the end of the last row.

### M2. Calendar events
1. The merged row keeps the calendar event of the first row that has one, and its calendar. Sathi moves that event's start and end to the merged row.
2. Sathi deletes the events of the other merged rows.
3. Order: update the kept event first, then delete the others. When a calendar step fails, Sathi puts back what it changed, does not merge, and shows "The calendar did not change, so Sathi did not merge." No row changes.
4. When no row has an event, no event is written.

### M3. Safety
1. Before the merge, a preview line shows the result: "{n} rows become 1, {start} to {end}".
2. After the merge, "Undo" shows until the next change on the page or `Timing.mergeUndoShow`. Undo puts back every row as it was (ids, times, texts, categories) and the calendar events (recreate the deleted events, put the kept event's times back). A failed calendar step on undo shows an error line; the rows still come back.
3. The automatic merge (rule 11c, gap 60 s) does not change.
4. Before a month file changes, the store keeps its normal safety (no data loss; follow `.claude/rules/storage.md`).

### M4. Place
1. Activities page Day view (Track 2).
2. Calendar page Day view, after the tracks merge (integration task): select activity blocks and press Merge, same engine call, same rules.

## Required tests (acceptance)

- C2.5 calendar-page day boundaries (rows across midnight, rows across 6 AM).
- C3.2 dedupe with `eventID` and `sourceEventID`; C3.3 twin events.
- C3.5 display join in Week and Month; none in Day; saved data unchanged.
- C4 hidden calendars saved, decode of old prefs without the field, new calendar shown.
- C5 reload on store change notification (fake notification source), no timer.
- C6 create, edit, delete through the spy writer; read-only cases; failed write keeps the popover.
- C7.1 to C7.6, each with both event modes.
- C8 totals: overlap counted once, all-day excluded, 6 AM boundary.
- M1 to M3: every allowed and blocked case, calendar update-then-delete order, rollback on failure, undo.
- UI: ViewInspector tests for the page header, the segment control, the shown-calendars list, the popover fields, and the Merge button states.
