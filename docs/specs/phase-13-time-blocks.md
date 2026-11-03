# Phase 13: Time blocks

The user starts a time block for a task. When the time block ends, Sathi writes 1 event to a calendar in the macOS Calendar app (for example a Gmail calendar). The calendar is the record of where the time went.

Design: https://claude.ai/artifact/RmtiYgZEmCG3a7nm6dmUz3 (artboards 2 to 8; artboard 1 is replaced by 7-A).
Terms: `GLOSSARY.md` (Time block, Planned length, Open time block, Target calendar, Block widget).

## Rules

1. A time block is not a habit. It has no streak, no goal, no history event, no stats, and no row in the day summary. It is not a `HabitID`. The calendar is the only record of a finished time block.
2. Only 1 time block runs at a time. A Start while a block runs ends the old block at that moment, saves it (rules 9 to 11), and shows the note "Saved {n} min on {title} to {calendar}." Then the new block starts.
3. Start popup (artboard 7-A): the menu card "Time block" has the button "Start a time block". The button opens a corner popup. This popup is the only Sathi popup that takes focus, because the user types in it. Content:
   - A title field with focus. The title is optional. Empty text uses "Work". The app trims spaces and changes each line break to a space. The maximum is `Limits.blockTitleMax` (60) characters.
   - Length chips: "Open", 15, 30, 40, 45, "1 h", "2 h" (`Limits.blockLengths` = 15, 30, 40, 45, 60, 120). The last chip used is selected (`TimeBlockPrefs.lastLength`, default 30).
   - A calendar menu. It shows the default target calendar (rule 13). A change applies to this block only.
   - The button "Start · ends at {time}" for a planned length, or "Start" for an open block. Return starts. Esc and the close button close the popup and start nothing.
4. Started note (artboard 7-B): after Start, a corner note shows "Started · {title}", "{length} · ends at {time} · {calendar}", and "Undo" for `Timing.cornerNoteDuration`. It never takes focus. Undo removes the block and writes no event. In "Menu bar only" mode the note does not show (rule 7).
5. Menu bar: while a block runs, the status item shows a clock icon and the minutes, before the buddy text. A planned block shows the minutes left ("12m"). An open block shows the minutes since Start ("42m", then "2h 5m"). The text changes 1 time per minute.
6. Menu card while a block runs (artboard 2): a ring (part of the planned length, or empty for an open block), the title (the user can edit it), "{n} of {length} min · ends at {time}" or "Since {start time} · {n} min", the calendar menu (the user can change it), and "End now".
7. Display mode: `TimeBlockPrefs.display`, `.menuBar` (default) or `.widget`. Settings label: "While a time block runs, show".
   - `.widget` (artboard 8-A): a pill in the top-right corner, 240 × 34 pt, that stays while the block runs. Content: a small ring, the title (cut with "…"), a live timer with seconds (countdown for a planned block, count-up for an open block), and an ✕ button. The ✕ means "End and save" (tooltip), the same as "End now". Hover shows "ends {time} · {calendar}". It never takes focus and has no animation.
   - `.menuBar` (artboard 8-B): no pill and no started note. The end popup (rule 9) and the check-in (rule 10) still show, because they need an answer.
8. End: "End now" in the menu or the ✕ on the pill ends the block now. A block shorter than `Timing.blockMinimum` (60 s) writes no event and shows the note "Too short, not saved." Otherwise Sathi saves the event (rule 11) and shows no popup.
9. Planned length passes (artboard 4): Sathi saves the event at once, for `startedAt ..< startedAt + length`. A calm corner popup shows "{length} on {title}", "Saved to {calendar} · {start} – {end}", "Done", and "+15 min". It never takes focus. Sound: `.ping` when `TimeBlockPrefs.playsSound` is on (default on). "+15 min" keeps the block running with a new end 15 min after the later of the old end and the tap (`Timing.blockExtend`). At the new end Sathi updates the saved event (title, calendar, start, end); a missing event is saved again for the whole range, and a failed update makes the block wait (rule 12). At the new end, this rule runs again. "Done" or the close button closes the popup. No answer: the popup stays until the user answers or starts a new block.
10. Open block check-in (artboard 5): `Timing.blockCheckIn` (2 h) after Start, a calm corner popup asks "Still on {title}?" with "Keep going" and "End now". "Keep going" sets the next check-in 2 h later. No answer: the block keeps running. At `Timing.blockCap` (12 h) after Start, Sathi ends the block at `startedAt + 12 h` and saves it.
11. Save: 1 event in the target calendar. Title = the block title. Start = `startedAt`. End = the end time. Notes and alerts are empty. Times are whole seconds. Time while the Mac sleeps or Sathi is closed counts, because events are wall-clock ranges.
12. Target calendar is gone, or the save fails (artboard 6-B): Sathi keeps the block, with `waitingForCalendar` set, and shows a corner popup "Your calendar “{name}” is gone" with the list of writable calendars and "Save here". Sathi never writes to a calendar that the user did not pick. The menu card shows the same choice while the block waits. Without calendar access the popup shows "Sathi can’t reach your calendars", "Allow calendar access in System Settings to save {length} on {title}.", and "Allow calendar access" (asks macOS) when Sathi has not asked yet, or "Open System Settings" after a denial, with no list. The menu card shows the same choice. Every access read (menu open, Settings page, access request, per-minute check, a failed save) shows the popup again when the access or the list changed. With access but no writable calendar it shows "No calendar you can save to. Add one in the Calendar app." While a block waits, the per-minute access check also reads the calendar list again; a change shows the popup again at the right size.
13. Calendars: Settings has its own "Time blocks" section in the sidebar, after the buddies (artboard 3, as its own page): calendar access status, "Default calendar" (the writable calendars grouped by account, with their color dots), the display mode (rule 7), and "Sound when a time block ends". Birthdays, Holidays, and subscribed calendars do not show. With no default yet, the Start popup selects the first calendar of the macOS default account.
14. Access: the first open of the Start popup or of the Settings card asks macOS for full calendar access. Denied or restricted: the menu card shows "Sathi needs calendar access to save your time blocks." and "Open System Settings" (Privacy & Security → Calendars). Start is off (artboard 6-A).
15. Restart: the running block is saved in `state.json`. After a restart it continues, and every deadline that passed while Sathi was closed runs at the next tick (an auto-end saves the event with the planned end).
16. Pauses ("Take a break"), weekdays, and days off do not affect a time block.

## Storage

- `LiveState.timeBlock: TimeBlock?`, default `nil`. Fields: `id`, `title`, `startedAt`, `length` (`.open` or `.minutes(n)`), `plannedEnd?`, `calendarID`, `savedEventID?`, `nextCheckIn?`, `waitingForCalendar`. Lenient decoding: a block that cannot be read loads `nil`.
- `Prefs.timeBlock: TimeBlockPrefs`: `defaultCalendarID?`, `lastLength` (30), `display` (`.menuBar`), `playsSound` (`true`). A missing key loads the default. An unknown value loads the default.
- No schema bump. Fixture tests load an old `prefs.json` and an old `state.json` without these keys.

## Port

`CalendarWriter` in `SathiCore/Ports`: `access`, `requestAccess() async -> CalendarAccess`, `calendars() -> [CalendarChoice]` (`id`, `title`, `account`, `colorHex`), `save(CalendarEventDraft) -> CalendarSaveResult` (`.saved(eventID)`, `.calendarMissing`, `.failed`), `update(eventID:draft:) -> CalendarSaveResult` (title, calendar, start, end of the saved event). Production: `EventKitCalendarWriter` in `SathiUI/Platform`. It creates `EKEventStore` on first use only. macOS 14+: `requestFullAccessToEvents`. macOS 13: `requestAccess(to: .event)`. Test: `SpyCalendarWriter`.

## Build

- `Resources/Info.plist`: `NSCalendarsFullAccessUsageDescription` and `NSCalendarsUsageDescription`.
- `Resources/Sathi.entitlements`: `com.apple.security.personal-information.calendars`. `build.sh` and `scripts/make-dmg.sh` sign with it.

## Slices

| Slice | Content | Check |
|---|---|---|
| 13a Core | Rules in `business-logic.md`, models, port, `SpyCalendarWriter`, Engine actions and loop, Copywriter, display text, decoding fixtures | `./scripts/test.sh`, lint |
| 13b Platform | `EventKitCalendarWriter`, Info.plist, entitlements, `AppEnvironment` | User tests the permission dialog and 1 real event in Gmail |
| 13c UI | Menu card, Start popup, started note, pill, end popup, check-in, calendar-gone popup, notes, `Night.block*` | ViewInspector tests, `/perf-check`, `--windows` |
| 13d Settings and docs | Settings card, `CLAUDE.md`, `README.md`, `ROADMAP.md`, website | Full Definition of done |

## Later

- Manual entry of a past time block (start and end typed by hand).
- Time blocks in Reports and the day summary (read the events back from EventKit).
- A keyboard shortcut that opens the Start popup.
