# Phase 14: Menu glance list

Status: planned 2026-11-03. Design: direction A on the canvas https://claude.ai/artifact/CQXDp5zP56e5zHYATZb5X4 (`Main.dc.html`).

## Goal

Make the menu panel short and calm. Today it is approximately 745 pt tall with 4 buddies, an empty Quick card, and an idle Time block. The target is approximately 470 pt for the same state. Also remove the gap between the menu bar and the top of the panel.

## Layout, top to bottom

1. Header: no change (greeting, date and streak, leaf logo).
2. Nap banner when paused: no change.
3. Habit list: 1 card (`Night.card`, `Night.border`, `cardRadius`) that holds 1 row per enabled habit, in `HabitID.allCases` order. A 1 pt `Night.divider` line separates the rows.
   - Row: ring (40 pt, buddy 22 pt), then a column with name + pill on line 1 and the goal text on line 2, then the action button.
   - The Reading "up next" line stays as line 3 when there is a pick.
   - All action buttons have the same width: `UIMetrics.menuActionWidth` (84 pt), height 30 pt, label centered. The labels do not change: "+1 glass", "Read now", "Breathe", "Move".
4. Sleeping rows: no change, below the habit list.
5. Full cards, only when they have content:
   - Quick reminders card when there is 1 or more reminder, or while the add form is open.
   - Time block card while a block runs, waits for a calendar, or calendar access is denied.
6. Tool row: 1 button for each tool that has no full card, side by side, equal width, 44 pt tall.
   - "Reminder" (pink, dashed border) opens the Quick add form in place of the row.
   - "Time block" (teal fill) opens the start popup (`openBlockStart`).
   - When both tools show full cards, there is no tool row.
7. Divider, then the footer: Reports, Settings, flexible space, "Take a break" menu button, Quit.
   - The menu has "30 min", "1 hour", "Rest of day". The actions do not change.
   - When there is 1 or more Quick reminder, the menu also shows the line "Quick reminders still show during a break."
   - The version text moves from the menu footer to the bottom of the Settings sidebar.
8. No empty space: the panel height is its content height.

## The gap under the menu bar

Hypothesis: the panel content becomes shorter after `MenuBarExtra` places its window. AppKit keeps the window bottom fixed, so the top edge moves down. Candidates:

- `e.refreshCalendarAccess()` in `MenuPanel.onAppear` can change the Time block card after placement.
- `CappedHeight` + `ScrollView` in `MenuCards` can report a different height in the first layout pass.

Step 1: prove the cause in the real app. Log the window frame at open and 1 second later. Then fix the cause, not the symptom. A test locks the fix: the panel height before and after `onAppear` work is the same.

## Not in scope

- No Core change. `goalText`, `pill`, `progress`, and the actions stay as they are.
- No change to the Quick add form, the Time block card content, or the popups.
- No change to saved data.

## Business rules to update first

`.claude/rules/business-logic.md`, Quick reminder rule 16: the empty card becomes the "Reminder" button in the tool row, and "Take a break" becomes a footer menu.

## Acceptance

1. The 4 action buttons have the same width.
2. With 4 buddies on, no reminders, and no block: the panel is shorter than 500 pt, and it shows the "Reminder" and "Time block" buttons and no Quick or Time block card.
3. With 1 reminder: the Quick card shows, and the tool row has only "Time block".
4. With a running block: the Time block card shows, and the tool row has only "Reminder".
5. The break menu items pause for 30 min, 1 hour, and the rest of the day.
6. The version text is in the Settings sidebar, not in the menu.
7. The panel opens directly under the menu bar, with no gap, in the real app.
