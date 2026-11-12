# Phase 20 plan: Activities polish

Spec: `docs/specs/phase-20-activities-polish.md` (binding authority).
UI demo: https://claude.ai/artifact/VTQQVFcFcqeKffu15Vbxwq

## Global Constraints

- Read `CLAUDE.md` and `.claude/rules/` first. They are binding.
- No code comments. Max 200 lines per file. No magic numbers: durations in `Constants/Timing.swift`, ranges in `Constants/Limits.swift`, UI sizes in `SathiUI/Constants/UIMetrics*.swift`, all user text in `Copywriter*`.
- SathiCore never imports AppKit or SwiftUI. Engine reads time only from `clock.now`.
- Tests first (Swift Testing, `EngineHarness`, fakes, ViewInspector for views). No real waits.
- Saved data: never lose data. Follow `.claude/rules/storage.md` and the `/data-migration` skill. Lenient decode for new fields.
- Business rules: update `.claude/rules/business-logic.md` before you change behavior.
- Each task ends with `./scripts/lint.sh` and `./scripts/test.sh` green, then 1 commit on `feat/app-window`. Do not push.
- Work only in `/Users/cefalo_1/Documents/Projects/Sathi-app-window`.

## Task 1: Top gap and row height

- Remove `.padding(.top, UIMetrics.titleBarInset)` from the main window pages: `ActivitiesPage.swift`, `ReportsPage.swift`, `TodayPage.swift`, `SettingsPageView.swift`. The content top stays `mainContentPadding.top` (28 pt). Check that no other user of `titleBarInset` breaks; delete the constant if it has no users.
- `ActivityTimelineRow.height(_:)`: one rule for work and away rows: `min(max, base + perHour * hours)`, base 44, perHour 8, max 88. Constants in `UIMetrics+ActivitiesV2.swift` (`activitiesRowBase`, `activitiesRowPerHour`, `activitiesRowMax`). Delete `activitiesRowShort/Medium/Long/Away` and `Limits.activityMediumRowHours` if unused.
- Tests: update `Tests/SathiUITests/Tracker/Reports/ActivityReportEditTests.swift:52` cases: 15m → 46, 1h → 52, 3h → 68, 7h → 88, 10h → 88, away 2h58m uses the same rule.

## Task 2: Standup button and sheet

- Remove `ActivityTextCard` from the bottom of `ActivityDayView` and `ActivityRangeView`.
- Add a header button in `ActivitiesPage.header`, before `ActivitiesExportButton`: "Standup" on a day range, "Summary" on week and month. Same look as the Export button.
- The button opens a SwiftUI `.sheet` with: title, the same text (`ActivityStandupText.make` for a day, `ActivityRangeText.make` for a range), a Close button and a Copy button ("Copy for standup" on day, current copy text on range). Copy uses the same copy action as today (`actions.copy` / pasteboard path) and shows the copied state.
- Text copy goes in `Copywriter`. Sizes in `UIMetrics`.
- Tests (ViewInspector): day view has no text card; header has the Standup button; the sheet content view shows the text and Copy calls the copy closure with that text.

## Task 3: Away places in the stats

- Core: `ActivityDayStats` gets `awayTotals: [ActivityCategoryTotal]`: one row per away place name (`awayPlaceName ?? Copywriter.trackerAwayPlace(awayPlace)`, unnamed → `Copywriter.trackerAway`), sorted by seconds desc then name. `percent` 0. `realWork`, `categories`, percent values do not change.
- `ActivityDayOverview` exposes `awayTotals`.
- `ActivityRangeStats`: replace the single `.away` total with one `.away` total per place (same naming), summed over the range. Check `ActivityMonthStats` and its callers (CSV/export, month rows) still work.
- UI `ActivityTableCard.day/range`: append away rows after category rows, name `"<place> · Away"` via Copywriter, color `NightHex.trackerAway`, no percent text, not in the table total or the category count. Add a flag to `CategoryTableInput`/`CategoryTableRow` if needed (e.g. `isAway`) so the row view shows "—" for percent and the total skips it.
- Tests: Core day + range totals per place, ordering, logged total unchanged; UI table has the away row, total unchanged.

## Task 4: Auto-merge on start

- Rule (Core, pure function, e.g. `Tracker/Rules/ActivityMerge.swift`): `canMerge(previous, next)` is true when same `kind` (`.work`), same trimmed text (case-sensitive equal), same category, `next.start - previous.end` is between 0 and `Timing.activityMergeGap` (60 s), and not both have an `eventID`.
- Engine: when a running activity starts (`startActivity` path, and the path that stores the ended running activity), if the last stored activity of the day can merge with the new one and no other activity lies between them, extend the stored one instead of storing a new row. The running activity keeps the stored activity's id and start so the stored row and running row become one. If the stored row has a calendar event, the calendar end time updates through the existing calendar edit path.
- Write the rule to `.claude/rules/business-logic.md`.
- Tests (EngineHarness): same text+category merges (one row, start of first, end of last); different category, different text, gap 2 min, an away row between, both with events: no merge.

## Task 5: Merge old stored rows once

- At engine start, if `prefs.tracker.mergedOldRows` is false: for each stored month file under `activities/`, apply the Task 4 rule to sorted rows of each day, merging runs. For each month file that changes, first write a backup copy `activities/YYYY-MM.backup.json` (same JSON), then save the merged file. Then set `mergedOldRows = true` and save prefs.
- Use the `ActivityStore` port. Add a backup method to the port and its fake if needed (`InMemoryActivityStore`). New pref field with lenient decode, default false (`/data-migration` skill).
- Merged rows keep the first row's id, event IDs and calendar ID; the last row's end.
- Tests: pass merges 6 touching Gaming rows into 1; backup written only for changed months; runs once (flag); rows that do not match stay; no row is lost (sum of lengths kept).

## Task 6: Engine: go away from the popup

- New `AwayCause.chosen`. New live field `TrackerAwayDetails.plannedPlace` (place + optional name), lenient decode.
- `package func goAway(place: AwayPlace, name: String?)`: clears the prompt, sets the planned place, `beginAway(at: now, cause: .chosen)` (the running activity ends at now, like `.onBreak`).
- A later lock or sleep while away updates the cause (existing rule) but keeps the planned place.
- `checkIdle`: a `.chosen` away ends on input only when input is at least `Timing.chosenAwayGrace` (120 s) after `awaySince`.
- `returnFromAway`: the stored away items get the planned place (and name); `lastAway` carries it; Welcome back shows it picked; then clear `plannedPlace`.
- Add `goAway` to `TrackerPromptActions` and wire it where the other prompt actions are wired.
- Update `.claude/rules/business-logic.md`.
- Tests (EngineHarness, FakeClock, fake presence): goAway ends the running activity; input before grace keeps away; input after grace returns and stores the place; lock then unlock stores the place; sleep/wake stores the place; Welcome back prompt shows it.

## Task 7: Popup Away toggle

- `PromptForm`: under Category, for non-event screens, an "Away" row with a toggle (off by default per popup). Off: no places. On: chips for `AwayPlace.choices`, the user's `awayPlaces`, and "+ Place" (adds via `actions.addPlace`, same field pattern as `PromptWhereBoxes`).
- Model: `ActivityPromptModel` gets `awayOn: Bool` and `awayPick` (place + name). Picking a chip sets it; turning the toggle off clears it.
- With a pick: For, Ask me, Calendar, Quiet rows hide; field and categories dim and are disabled; the primary footer button reads "Go away · <place>" and calls `actions.goAway`. Return key does the same.
- `TrackerPromptState` must carry the away place list for the prompt (check how `PromptWhereBoxes` gets `form.places`).
- Text in Copywriter, sizes in UIMetrics, ids `tracker.away.toggle`, `tracker.away.place.<raw>`, `tracker.away.custom.<name>`.
- Tests (ViewInspector): toggle off hides chips; on shows them; a pick hides the 4 rows and the button calls goAway with the place; event screen has no Away row.

## Task 8: Settings add place

- `TrackerPlacesRow`: show built-in places (read only) and the user's places (removable, as today), plus a "New place" text field and "+ Add place" button that call `engine.addAwayPlace`. Hide the field at `Limits.awayPlaceMax`. Clear the field after a successful add.
- Tests (ViewInspector + engine): add a place adds it to prefs; duplicate or built-in name is refused; field hidden at max.
