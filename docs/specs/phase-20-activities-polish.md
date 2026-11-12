# Phase 20: Activities polish

Goal: make the Activities page tighter, and make away time count like categories in the stats and the popups.

Branch: `feat/app-window` (worktree `../Sathi-app-window`).

## 1. Less top space on every page

- Now: `mainContentPadding.top` (28) + `titleBarInset` (28) = 56 pt above the page title.
- The traffic lights sit in the sidebar. The content does not need the title bar inset.
- Remove `.padding(.top, UIMetrics.titleBarInset)` from `ActivitiesPage.swift:22`, `ReportsPage.swift:30`, `TodayPage.swift:12`, `SettingsPageView.swift:17`.
- The content top stays at `mainContentPadding.top` (28 pt). Total gap: 56 pt → 28 pt.

## 2. Away places count like categories

Decision: keep 2 lists (categories, away places). Away places show in the stats and in the "What now?" popup. "Break" stays a category.

Stats (Core):
- `ActivityDayStats` gets `awayTotals`: 1 row for each away place (Sleep, Lunch, ...), sorted by time.
- `ActivityRangeStats.swift:76` splits the single "Away" row by place.
- Logged total and category percent do not change. Away time is not logged time.

Table (UI):
- `ActivityTableCard` adds away rows after the category rows: name + "· Away", away grey, no percent.

"What now?" popup:
- `PromptForm.swift:15` gets a row "Away" under Category: built-in places, your own places, "+". It shows in every popup that uses `PromptForm` (What now?, Activity ended, shortcut panel, Still on it?). The calendar-event popup does not get it.
- The row is an "Away" toggle, off by default. Off: the places are hidden. On: the places show.
- Pick a place: For, Ask me, Calendar and Quiet hide. The field and the categories dim. The main button reads "Go away · <place>".
- Tap the button: the running activity ends now, and away time starts with that place.

Engine:
- New `goAway(place:name:)` calls `beginAway(cause: .chosen)` and keeps the planned place.
- These events end the away time:
  1. Unlock or wake. A lock or sleep after the pick keeps the planned place.
  2. Input 2 min or more after the pick (`Timing.chosenAwayGrace`).
- On return, the away rows already have the place. "Welcome back" shows it as picked.

Settings:
- `TrackerPlacesRow` gets a "New place" field and an "+ Add place" button. It uses `addAwayPlace` (same limits and name rules as the popup).

Saved data:
- 1 new live field `away.plannedPlace`, lenient decode, no schema bump (`/data-migration`).

## 3. Timeline row height by duration

- Replace the 3 fixed heights in `ActivityTimelineRow.swift:41` with: `44 + 8 pt × hours`, max 88 pt.
- Away rows use the same rule (now they are always 40 pt).
- 15m → 46 pt, 3h → 68 pt, 7h → 88 pt.

## 4. Standup text in a header button

- Remove `ActivityTextCard` from the bottom of `ActivityDayView.swift:26` and `ActivityRangeView.swift:26`.
- Add a "Standup" button next to Export in `ActivitiesPage.swift:44` ("Summary" on Week and Month).
- The button opens a sheet with the text and a Copy button.

## 5. Auto-merge of same activities

Rule: 2 activities merge when all of these are true:
- Same text, same category, same kind (work).
- The second starts at the end of the first, or no more than 1 min later (`Timing.activityMergeGap`).
- No other activity or away row sits between them.
- Not both have their own calendar event. A merge keeps the first event and moves its end time.

New activities: on start, Sathi extends the last stored activity and stores no new one.

Old activities (decision: merge them too):
- A one-time pass at app start merges stored rows in `activities/YYYY-MM.json` with the same rule.
- Before the pass, Sathi writes a backup copy of each file it changes (`activities/YYYY-MM.backup.json`).
- A flag in prefs (`tracker.mergedOldRows`) makes sure the pass runs only once.

## Tests (written first)

- Stats: away rows for each place, sums, order. Logged total and percent do not change.
- Engine: `goAway` ends the running activity. Unlock, wake, and input after the grace store the planned place. Input before the grace does not end the away time.
- Merge: same text and category merge. A different category, a gap over 1 min, a row between, or 2 calendar events stop the merge.
- Old rows: the pass merges, writes the backup, runs once, and loses no data.
- UI: row height formula, away chips in the popup, standup button opens the sheet, no text card at the bottom.

## Performance

No new timers or animations. The grace check uses the idle check that already runs. The old-rows pass runs once.

## Risks

1. The `.chosen` cause adds a new path to the away flow.
2. The old-rows pass rewrites saved data. The backup and the run-once flag reduce the risk.
