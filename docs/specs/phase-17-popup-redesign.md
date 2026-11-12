# Phase 17 finish: tracker popup redesign (light red, every option visible)

Branch: `feat/activity-tracker` (local, not pushed). Work on a new branch `feat/tracker-popup-redesign` from it, then merge back with `--no-ff`.

Approved design (user, 2026-11-10): https://claude.ai/artifact/9P4jzUd4LyfcigrVdcA4c5
Read the 6 boards there before you code. They are the target. Match spacing, sizes, and colors.

## Decisions (final)

1. **Accent color:** light red `#FF8A80` replaces the tracker yellow everywhere the tracker uses it (popups, menu card, Activities report, tracker Settings, My day sidebar switch). Text on the accent: `#2A0E0C`. Selected chip text: `#FFB3AB`. Accent fill: `#FF8A80` at 14–16% alpha.
2. **Everything visible.** No option hides behind a summary line or an "options" panel. The current `TrackerSummaryLine` + `TrackerOptionsPanel` go away.
3. **Recent and Category are dropdowns** (they grow over time):
   - Recent: a full-width dropdown button "Recent · Pick from your last 10". It opens a list of up to 10 recent activities, newest first, each with its color dot and category. A pick starts that activity at once (rule 17, unchanged behavior).
   - Category: a dropdown button with the selected category dot and name. The list shows every category with ✓ on the selected one, and "No category" at the end.
4. **`Limits.recentMax` = 10.** Remove `recentInCorner` and `recentInCenter` (both prompts list up to 10 in the dropdown).
5. **Other rows stay as chips:** For (15 min, 30 min, 1 h, Open), Ask me (When it ends, 5 min after, 15 min after).
6. **No empty space.** No `Spacer` / flex-grow between the form and the buttons; each panel is as tall as its content.
7. Header of every popup: a 36–40 pt rounded icon tile (accent at 14%, accent stroke icon), an uppercase eyebrow in the accent color, and the title in white.

## Popups

| Popup | File(s) | Content, top to bottom |
|---|---|---|
| B · Log activity (center, 560 wide incl. margin) | `CenterPromptView` | Header (pencil, "LOG ACTIVITY · {time}", "What are you doing now?") · text field (accent border) · Recent dropdown · options box (`Night.trackerInset` fill, 14 pt radius): For chips, Category dropdown, Ask me chips, divider, Add to calendar check box + calendar picker, "No popups until it ends" + "until {time}" + switch · Start (accent) + Close · key hint "↵ start · esc close · {shortcut} from anywhere" |
| A · What now? (corner, 380 card) | `WhatNowPopup` (+ `TrackerSwitchRow` after Done, + Continue button after a session) | Same as B, smaller (rows 26–28 pt high, labels 64 pt wide). Buttons Start + Skip. |
| C · Still on it? (corner) | `StillOnItPopup` | Header (clock icon, "STILL ON IT? · {n} MIN SO FAR", dot + activity text) · big accent "Yes, {askEvery} min more" · "Or more" + 5 min + 30 min chips · "Done · pick when you switched" + Skip (both outline). Late form keeps its text, same styles. |
| D · Welcome back (center) | `WelcomeBackView` | Header (house icon, "AWAY {start} – {end} · {n} MIN", "Welcome back. What now?") · accent "Back to {last}" with ↵ · "Something new" + "I was here" (only after idle) · box "Where were you? · optional" place chips · while-away event rows (keep) · key hint |
| F · Calendar note (corner) | `TrackerNoteView` | Header (calendar icon, "FROM YOUR CALENDAR · {time}", title, "{start} – {end} · {calendar}") · Category dropdown · Not attending + Undo · "Logged now · this note closes in 1 min" |
| Ask-first (corner) | `EventAskPopup` | Same header as F, Category dropdown, Yes (accent) + No |
| End of day (center) | `EndOfDayView` | Recolor only (accent → light red). No layout change. |
| Menu card | `TrackerMenuCard` | Recolor only. |

## Code plan

1. **Theme first:** `NightPalette.swift`: `Night.tracker` → `#FF8A80`, `trackerFill` → a dark red tint (for example `#2E1A1C`), add `trackerOnAccent` `#2A0E0C` and `trackerSelectedText` `#FFB3AB`. Do not touch `Night.spark` (other features use it). Check `DaysOffSource`, `BreathMood`, `MyDayGroup` use the tracker color on purpose.
2. **Constants:** `Limits.recentMax` 10; delete `recentInCorner`, `recentInCenter`. New sizes in `UIMetrics+TrackerPrompts.swift` (icon tile, dropdown height, options box padding/radius, label widths). No magic numbers.
3. **New shared views** in `Features/Tracker/Prompts/`:
   - `TrackerRecentMenu` (dropdown, up to 10, pick → `actions.start`).
   - `TrackerCategoryMenu` (dropdown, ✓ on selected, "No category").
   - `TrackerOptionsBox` (For, Category, Ask me, calendar, quiet) used by A and B.
   - Update `TrackerHeader` (icon tile + eyebrow + title + optional detail).
4. **Delete** `TrackerRecentChips`, `TrackerSummaryLine`, `TrackerOptionsPanel`, `TrackerCategoryRows` when nothing uses them (and their tests, replaced by new ones).
5. **Rebuild** each popup in the table. Keep every action and accessibility identifier that tests or the controller use (`tracker.start`, `tracker.skip`, `tracker.close`, `tracker.calendar.check`, `menu.tracker.*`, …). Keyboard behavior (G64, rule 62) must not change.
6. **Copy:** new strings in `Copywriter+TrackerPrompts.swift` ("Recent", "Pick from your last 10", "Or more", "No category", "until {time}", eyebrows in uppercase, "Logged now · this note closes in {n} min"). Spec rule 17 and rule 41 text: update "A shows 3, B shows 4" to "a Recent dropdown with up to 10".
7. **Spec and rules:** `docs/specs/phase-17-activity-tracker.md` rules 12, 17, 18, 44 (layout words), `.claude/rules/business-logic.md` tracker rule 3 if wording changes. Note the color in the spec "Settings/Theme" line if any.

## Tests (write first)

- `RecentList` / `recentActivities`: up to 10, newest first, same text+category once.
- `TrackerRecentMenu`: lists 10, a pick calls `start` with that text and category.
- `TrackerCategoryMenu`: lists all categories, ✓ on selected, "No category" clears it.
- Each popup: every option row is present without opening anything (find For, Ask me, calendar check, quiet switch, Recent and Category buttons).
- Update existing prompt tests that look for recent chips or the summary line. Never weaken a test; say why each changes.
- Colors: a `NightPaletteTests` row for the tracker accent `#FF8A80`.

## Checks (Definition of done)

1. `./scripts/test.sh` and `./scripts/lint.sh` pass. No file over 200 lines. No comments.
2. `swift build -c release`: no new warnings.
3. Render every popup to PNG (temporary `WebsiteShots`-style test into the scratchpad, then delete it) and compare with the design boards. Fix gaps.
4. Ask the user, then `./build.sh --install` and `./scripts/perf.sh`. The user runs `./scripts/perf.sh --windows`.
5. Website: re-render `tracker-what-now.png`, `tracker-still-on.png`, `tracker-report.png`, `tracker-end-of-day.png` (`SATHI_SHOTS="$PWD/site/screenshots" swift test --filter WebsiteShots`), update `site.css` `--tracker` to `#ff8a80`, run `./scripts/check-site.sh`.
6. Commit on the branch (`feat(tracker): light red popups, every option visible, dropdowns`), merge into `feat/activity-tracker` with `--no-ff`, update `PROGRESS.md` (status + session log). Ask before any push or merge to `main`.
