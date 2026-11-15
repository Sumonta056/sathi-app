# Phase 23: To-dos (Apple Reminders)

Goal: show, add, edit, and complete the user's Apple Reminders inside Sathi, so the user does not need to open the Reminders app.

- Branch: `feat/todos` (worktree `../Sathi-todos`, from `main` 2d65653)
- Status: plan approved 2026-11-15. Business rules written (`.claude/rules/business-logic.md`, section "To-dos", Activity tracker 11g, Calendar page 15).
- Design: https://claude.ai/artifact/9nSkS3YKZ8uoqcVeKT548n, page "Final design" (To-dos page = option A)
- Terms (`GLOSSARY.md`): To-do, To-do list, Due today

## Decisions (from the grill, 2026-11-14)

1. Apple Reminders is the only store. Sathi keeps no copy of a to-do on disk.
2. Two-way. In Sathi the user can add, edit (title, notes, due date and time, list), mark done or not done, delete (with confirm), and move a to-do to another list.
3. Lists: the user can create a list (name, 1 of 12 colors, account; iCloud first) and rename a list. Sathi cannot delete a list.
4. The Apple API has no list groups, sections, flags, tags, subtasks, list icons, or manual order. Sathi shows lists flat and does not show these items.
5. Sort order: to-dos with a due date first (earliest at the top), then to-dos with no date (newest at the top).
6. Completed to-dos stay hidden behind "N Completed · Show". The Completed tile shows the last 30 days.
7. The feature is off by default. Sathi asks for Reminders access only when the user turns it on.
8. All lists show at first. The user can hide a list in Settings.
9. The due time uses the 5-minute chip grid (`TimeMenu`).
10. The Quick panel shows a "Due today" card: the count, the first 3 to-dos (each can be ticked), and overdue to-dos in coral. The card hides when nothing is due.
11. There is no separate popup. A to-do with a time that comes due inside tracker hours opens the activity prompt with the reason "To-do due". This happens only when the tracker is on and the "Ask when due" switch is on.
12. When nothing runs, the buttons are Later / Done / Start it. When an activity runs, the buttons are Later / Done / Keep <activity> / Switch to it.
13. When an activity that started from a to-do ends, the prompt asks once: "Mark <to-do> done?". A tick alone logs no activity.
14. The 10 PM summary gets 1 line, "To-dos: N done · M left for today". To-dos do not change the "all goals met" check.
15. Calendar page: a to-do with a time shows as a chip at its time. A to-do with only a date shows in the all-day row. To-do lists appear in "Shown calendars". Sathi never copies a to-do into a calendar.
16. Quick reminder stays as it is. It will be removed in a later phase.

## Architecture

```
SathiCore/Ports/TodoStore.swift          protocol (access, lists, todos, write calls)
SathiCore/Todos/                         models + pure rules (no EventKit)
SathiCore/Engine/Engine+Todos*.swift     cache, actions, due check, prompt glue
SathiUI/Platform/EventKitTodoStore*.swift  EKReminder impl, shares the EKEventStore
SathiUI/Features/Todos/                  page, rows, edit card, list form
Tests/SathiTestSupport/SpyTodoStore.swift  fake
```

- Sync: `EventKitCalendarChangeSource` already observes `EKEventStoreChanged` with `object: nil` (`Sources/SathiUI/Platform/EventKitCalendarChangeSource.swift:16`). Reminders changes post the same notification. `Engine+CalendarPageSync.swift:24-33` also listens when `prefs.todos.isOn`. A change marks the to-do cache stale and calls `requestTick()`. There is no new timer.
- Store: `EventKitTodoStore` gets the `EKEventStore` of `EventKitCalendarWriter` (`EventKitCalendarWriter.swift:7`). One store serves the whole app.
- Async: `fetchReminders(matching:)` uses a callback. The port exposes `async` reads. The Engine keeps 1 snapshot (`TodoSnapshot`) and replaces it only when the store revision changes.

## Track A: Core foundation (first, alone)

| File | Job |
|---|---|
| `SathiCore/Todos/Todo.swift` | `Todo` (id, listID, title, notes, due: `TodoDue?` (date only or date + time), priority, isDone, doneAt, createdAt, repeats, url) |
| `SathiCore/Todos/TodoList.swift` | `TodoList` (id, name, colorHex, accountID, accountName, canEdit) |
| `SathiCore/Todos/TodoDraft.swift` | `TodoDraft` and `TodoEdit` (fields that the user can write) |
| `SathiCore/Todos/TodoListDraft.swift` | name, color, accountID |
| `SathiCore/Todos/TodoSmartList.swift` | `today, scheduled, all, completed` + `matches(_:now:calendar:)` |
| `SathiCore/Todos/TodoRules.swift` | sort, `dueToday`, `isOverdue`, counts per list, 30-day completed window |
| `SathiCore/Todos/TodoPrefs.swift` | `isOn` (false), `hiddenListIDs`, `askWhenDue` (true), `newListAccountID` |
| `SathiCore/Todos/TodoSnapshot.swift` | lists + open to-dos + recent completed, with `revision` |
| `SathiCore/Ports/TodoStore.swift` | `access`, `requestAccess() async`, `accounts()`, `lists()`, `todos(listIDs:completedSince:) async`, `add`, `update`, `setDone`, `move`, `delete`, `createList`, `renameList` |
| `SathiCore/Constants/Limits+Todos.swift` | `todoCompletedDays = 30`, `todoQuickPanelMax = 3`, `todoListColors` (12 hex values) |
| `SathiCore/Formatting/Copywriter+Todos.swift` | all To-dos text |
| `SathiCore/Models/Prefs.swift:3-12, 96-108` | add `todos: TodoPrefs` + 1 `lenient` line |
| `SathiCore/Models/MainPage.swift:3-9` | add `case todos` |
| `Tests/SathiTestSupport/SpyTodoStore.swift` | fake: settable lists, to-dos, access; records each write |
| `Tests/SathiTestSupport/EngineHarness.swift:24-57` | build and expose `SpyTodoStore` |
| `SathiCore/Engine/Engine.swift:77-91` | new port `todos: TodoStore = NoTodoStore()` |

Tests:
- `TodoRulesTests`: sort order (decision 5); due today includes overdue; a date-only to-do is due all day; the completed window drops day 31.
- `TodoSmartListTests`: each tile matches the right to-dos and counts.
- `TodoPrefsTests`: default values; JSON with no `todos` key decodes to defaults (storage rule 9).
- `FileStateStoreTests`: an old `prefs.json` still loads.

## Track B: To-dos page, settings, EventKit (after A)

| File | Job |
|---|---|
| `SathiUI/Platform/EventKitTodoStore.swift` (+`+Mapping`, `+Lists`, `+Write`) | EKReminder read/write; access with `requestFullAccessToReminders` on macOS 14, `requestAccess(to: .reminder)` on 13 |
| `Resources/Info.plist:25-28` | add `NSRemindersFullAccessUsageDescription` and `NSRemindersUsageDescription` |
| `Sources/Sathi/AppEnvironment.swift:22-35` | build `EventKitTodoStore(store: writer.store)` and inject it |
| `SathiCore/Engine/Engine+Todos.swift` | snapshot load, stale flag, `todoPage(_ smart or list)` |
| `SathiCore/Engine/Engine+TodoActions.swift` | add, edit, done, move, delete, create list, rename list; each refreshes the snapshot |
| `SathiCore/Engine/Engine+CalendarPageSync.swift:24-33` | also listen when `prefs.todos.isOn` |
| `SathiUI/Features/Todos/` | `TodosPage`, `TodoSideColumn`, `TodoSmartTiles`, `TodoListRow`, `TodoItemsColumn`, `TodoRow`, `TodoAddField`, `TodoEditCard`, `TodoListForm`, `TodoAccessGate` |
| `SathiUI/Constants/UIMetrics+Todos.swift`, `Theme/NightPalette+Todos.swift` | sizes; orchid `#E58CF5` |
| `SathiUI/Features/Main/MainSidebar.swift:25-38`, `SidebarRail.swift:18-19`, `MainView.swift:23-32`, `MainRoute.swift:12-14` | page item gated by `prefs.todos.isOn`, falls back to Today when off |
| `SathiCore/Models/MainPage.swift:11-21`, `Features/Settings/SettingsPageView.swift:22-29`, `Main/SidebarSettingsStyle.swift`, `Copywriter+Main.swift:23` | new Settings page "To-dos" |
| `SathiUI/Features/Settings/Todos/` | `TodosSettingsPage` (on/off, access status, shown lists, Ask when due) |

Tests:
- `EngineTodoFlowTests`: turning on asks for access once; denied access shows the gate; each action calls the spy with the right values; a store change refreshes the snapshot; no write when access is denied.
- `EngineMainPageTests`: `.todos` falls back to Today when off.
- `Todos/TodosPageTests`, `TodoRowTests`, `TodoEditCardTests`, `TodoListFormTests`, `TodosSettingsTests` (ViewInspector).

## Track C: Quick panel, activity prompt, day summary (after A)

| File | Job |
|---|---|
| `SathiUI/Features/MenuBar/QuickDueTodayCard.swift` | the card; goes into `MenuPanel.swift:9-18` after `QuickNowRow` |
| `SathiCore/Tracker/PromptKind.swift:3-9` | add `todoDue` |
| `SathiCore/Tracker/PromptReason.swift:3-18` | add `todo` |
| `PromptState` | add optional `todoID` (saved in `state.json`; run `/data-migration`) |
| `RunningActivity` | add optional `todoID` and `askedTodoDone` (saved; `/data-migration`) |
| `SathiCore/Engine/Engine+TodoDue.swift` | next due time for `TickPlanner`; opens `.todoDue` once per to-do and due time |
| `SathiCore/Tracker/ActivityPromptBuilder.swift:6-14, 49-65` | `todo` screen (idle and running texts); mark-done card on the `ends` screen |
| `SathiCore/Tracker/TrackerPromptActions.swift:3-24`, `Engine+TrackerPromptState.swift:78-99` | `startTodo`, `doneTodo`, `markTodoDone(Bool)` |
| `SathiUI/Features/Tracker/Prompt/PromptHeader.swift` (icon), `PromptCommands.swift:12-45`, new `PromptTodoDoneCard.swift`, `NightPalette+Prompt.swift:21-29` | UI for the new reason |
| `SathiCore/Stats/DaySummary.swift`, `Engine+DaySummary.swift:6`, `Copywriter+DaySummary.swift`, `Features/DaySummary/DaySummaryCard.swift` | optional To-dos line |

Tests:
- `EngineTodoDueTests`: the prompt opens at the due time inside tracker hours only; not when the tracker is off, the switch is off, the to-do has no time, or it is already done; it opens 1 time only; 2 to-dos due together give 1 prompt with both; Later keeps the running activity; Switch ends it and starts the to-do; Done ticks it.
- `EngineTodoEndsTests`: ending a to-do activity asks once; Mark done calls `setDone`; Not yet never asks again.
- `TickPlannerTests`: the next due time shortens the delay.
- `DaySummaryTests`: done and left counts; the all-goals verdict does not change.
- `QuickDueTodayCardTests`, `ActivityPromptTodoTests` (ViewInspector).
- Migration tests: old `state.json` with no `todoID` decodes.

## Track D: Calendar page (after A)

| File | Job |
|---|---|
| `SathiCore/CalendarPage/CalendarBlock.swift:15-22` | `source` gains `.todo(id)` |
| `SathiCore/CalendarPage/CalendarBlockBuilder.swift` | timed to-do = chip at its time; date-only = all-day |
| `SathiCore/Engine/Engine+CalendarPage.swift:23-73` | merge to-dos into `CalendarPageData`; cache key adds the to-do revision |
| `Engine+CalendarPageCalendars.swift:14-37`, `Features/Calendar/CalendarShownList.swift` | "To-do lists" group; reuses `hiddenCalendarIDs` |
| `SathiUI/Features/Calendar/CalendarTodoChip.swift`, `CalendarTimeGrid.swift`, `CalendarAllDayRow.swift` | chip with a tick circle |

Tests:
- `CalendarBlockBuilderTests`: timed vs date-only placement.
- `EngineCalendarPageTests`: hidden to-do list hides its chips; ticking from the grid calls `setDone`.
- `Calendar/CalendarTodoChipTests`.

## Rules and docs

- `.claude/rules/business-logic.md`: new section "To-dos" with rules 1-16 (the decisions above), plus "Activity tracker 11g" (To-do due) and "Calendar page 15". Write these before any code.
- `docs/ROADMAP.md`: add "Phase 23: To-dos" after Phase 22.
- `CLAUDE.md` module map: `Todos/`, `Ports/TodoStore`, `Features/Todos/`.
- Website and README after it ships (`/sathi-website`).

## Order and worktrees

1. Track A on `feat/todos`. Merge when green.
2. Tracks B, C, D in parallel on 3 worktrees from `feat/todos`: `feat/todos-page`, `feat/todos-prompt`, `feat/todos-calendar`. Each uses test-writer → implementer → code-reviewer.
3. Merge B, then C, then D into `feat/todos`. Run all checks. Then merge into `main` after you approve.

## Performance

- No new repeating timer. The due check feeds the existing `TickPlanner` with the next due time.
- Reads happen only on start, on a store change, or when the page opens. Pages read the cached snapshot.
- 1 new `@Published` value (`todoSnapshot`). It changes only when the store revision changes.
- Run `/perf-check` after Tracks B and C. The user runs `./scripts/perf.sh --windows`.

## Risks and open points

1. Decided: fix the 2 calendar texts in `Info.plist` (they still say "It does not read your events") in Track B, together with the new Reminders texts.
2. A large Completed history can be slow to fetch. The 30-day window limits it.
3. Exchange lists can be read-only. `canEdit` hides the edit controls for them.
4. Repeating to-dos: Apple makes the next copy when one is ticked. Sathi only shows "repeats" and does not edit it.
5. Tracks B, C, and D all edit `Copywriter+Todos.swift` and `Engine.swift`. Track A creates these files in full, so the later merges stay small.
