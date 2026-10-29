# Quick Reminder Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The user writes a one-off reminder for a particular time. A calm corner popup shows it at that time and brings it back until the user taps Done.

**Architecture:** The Core gets a `QuickReminder` model that `LiveState` saves, a `QuickPrefs` level in `Prefs`, and 2 Engine extensions. The first extension holds the actions (add, delete, done, snooze). The second holds the loop (show, ignore timer, lock), and `tick()` calls it next to the buddies. The UI adds a menu card with an inline form, a corner popup, a snoozed note, a lock view, and a Settings card. They use 4 new `ReminderPresenter` methods.

**Tech Stack:** Swift 5.9, SwiftUI + AppKit, Swift Testing, ViewInspector, macOS 13+.

**Spec:** `docs/specs/phase-12-quick-reminder.md`. Rule numbers below ("R5") point to it. Design: https://claude.ai/artifact/Cj6jHTShgvTFXxyZ6ZFPjs

## Global Constraints

- Work on branch `feat/quick-reminder`. `main` is protected. Ask the user before every `git commit` and `git push`.
- No code comments (`no_comments` lint). Max 200 lines per file.
- Values go in constants: `Limits.quickTextMax = 80`, `Limits.quickMax = 20`, `Limits.quickChips = [5, 15, 30, 60]`, `Limits.quickNoteTextMax = 24`, `UIMetrics.quickVisibleRows = 4`, `Night.quick = Color(hex: 0xFF9FB8)`, `Night.quickFill = Color(hex: 0x2A1C25)`, `Night.quickBorder = Color(hex: 0x4A2E3D)`.
- SathiCore never imports AppKit or SwiftUI. The Engine reads time only from `clock.now`.
- `package` access only for what another target uses.
- Tests first for every behavior. Use `EngineHarness` and the fakes. No real waits.
- No new timer. Animations cap at 30 fps and pause when hidden (reuse `Shake`).
- Never lose user data: the new keys decode leniently (`lenient`, `lenientArray`). Follow the `/data-migration` skill. No schema bump.
- Copy is exact: "Quick reminders", "Quick reminder", "Remind me to", "or at", "Add reminder", "Cancel", "Done", "In {n} min", "QUICK REMINDER · {time}", "You set this at {time}.", "No snoozes left. It stays until you tap Done.", "“{text}” comes back at {time}", "Showing now", "Tomorrow", "Quick reminders still show during a break.", "You have 20 quick reminders. Delete one to add more.", "Hold for Done", "Delete this reminder".

## Review Focus

1. A time picked at the current minute, or an earlier minute today, must go to tomorrow and never fire at once. Test: Task 2 `atPastMinuteGoesTomorrow`.
2. 2 reminders due at the same minute must show 2 popups with independent snoozes. Test: Task 4 `twoDueTogetherShowBoth`.
3. A delete from the menu while the popup or the lock shows must close it. Test: Task 4 `deleteWhileShowingCloses` and `deleteWhileLockedClosesLock`.
4. A quick lock and a buddy lock must never show together. Test: Task 5 `quickWaitsForBuddyLock` and `buddyWaitsForQuickLock`.
5. A hand-edited `state.json` (blank text, 25 items, a bad date) must keep every valid item and never lose other live state. Test: Task 2 `decodeDropsBadKeepsGood` and `decodeKeepsEarliestTwenty`.

---

### Task 1: Spec, business rules, branch

**Files:**
- Modify: `.claude/rules/business-logic.md` (add a section "Quick reminders" with R1 to R18 in short form)
- Modify: `docs/ROADMAP.md` (add "Phase 12: Quick reminder" with the task list of this plan)
- Already written: `docs/specs/phase-12-quick-reminder.md`

- [ ] **Step 1:** Run `git switch -c feat/quick-reminder`. Expected: you are on the new branch.
- [ ] **Step 2:** Add the business-logic section and the roadmap phase.
- [ ] **Step 3:** Ask the user, then commit: `docs: quick reminder spec and business rules`.

---

### Task 2: Core models, time math, decoding

**Files:**
- Create: `Sources/SathiCore/Quick/QuickReminder.swift` (model + lenient decode)
- Create: `Sources/SathiCore/Quick/QuickPrefs.swift`
- Create: `Sources/SathiCore/Quick/QuickTime.swift` (`QuickTime`, `QuickAddResult`, `QuickText`)
- Modify: `Sources/SathiCore/Constants/Limits.swift` (4 constants from Global Constraints)
- Modify: `Sources/SathiCore/Models/LiveState.swift` (`quickReminders`)
- Modify: `Sources/SathiCore/Models/Prefs.swift` (`quick`) and its decoder
- Test: `Tests/SathiCoreTests/QuickTimeTests.swift`, `QuickReminderDecodingTests.swift`, `QuickPrefsDecodingTests.swift`

**Interfaces:**
- Produces:
  - `QuickReminder` and `QuickPrefs` as in the spec's "Data shape". `QuickReminder.init(id: UUID = UUID(), text: String, due: Date, createdAt: Date)` sets `snoozes = 0` and `snoozedUntil = nil`.
  - `enum QuickTime { case inMinutes(Int), at(minutes: Int); func date(now: Date, calendar: Calendar) -> Date }`
  - `enum QuickAddResult { case added(UUID), empty, full }`
  - `enum QuickText { static func clean(_ raw: String) -> String }`. It trims, changes line breaks to spaces, and cuts to `Limits.quickTextMax`.
  - `extension Array where Element == QuickReminder { func kept() -> [QuickReminder] }`. It drops empty text, sorts by `fireDate` then `createdAt`, and keeps the first `Limits.quickMax`.
  - `LiveState.quickReminders: [QuickReminder] = []`, `Prefs.quick = QuickPrefs()`

- [ ] **Step 1: Write the failing tests**

```swift
@Test func inMinutesAddsWholeMinutes() {
    let now = day(2026, 3, 4, 10, 0).addingTimeInterval(0.4)
    #expect(QuickTime.inMinutes(15).date(now: now, calendar: .current) == day(2026, 3, 4, 10, 15))
}
@Test func atLaterMinuteIsToday() {
    #expect(QuickTime.at(minutes: 14 * 60 + 37).date(now: day(2026, 3, 4, 10), calendar: .current) == day(2026, 3, 4, 14, 37))
}
@Test func atPastMinuteGoesTomorrow() {
    let now = day(2026, 3, 4, 10, 0)
    #expect(QuickTime.at(minutes: 10 * 60).date(now: now, calendar: .current) == day(2026, 3, 5, 10, 0))
    #expect(QuickTime.at(minutes: 9 * 60).date(now: now, calendar: .current) == day(2026, 3, 5, 9, 0))
}
@Test func cleanTrimsJoinsAndCuts() {
    #expect(QuickText.clean("  Call\nmom  ") == "Call mom")
    #expect(QuickText.clean(String(repeating: "a", count: 90)).count == 80)
}
@Test func oldStateWithoutKeyLoadsEmpty()      // {"bottleLevel":0.5} → quickReminders == [], bottleLevel == 0.5
@Test func decodeDropsBadKeepsGood()          // 3 items: valid, text "  ", due "nope" → 1 item; lastDaySummary still decoded
@Test func decodeKeepsEarliestTwenty()        // 25 valid items → 20, the earliest fireDate ones, in fireDate order
@Test func decodeCutsLongText()               // 100 chars → 80
@Test func quickPrefsDefaults()               // {} → .persistent, showsCloseButton true
@Test func quickPrefsUnknownStrictness()      // {"strictness":"wild"} → .persistent
@Test func prefsWithoutQuickKeyKeepsOthers()  // old prefs.json fixture → quick == QuickPrefs(), water prefs unchanged
@Test func quickReminderRoundTrips()          // encode → decode equal, dates whole seconds
```

- [ ] **Step 2:** Run `./scripts/test.sh SathiCoreTests`. Expected: FAIL. The types `QuickTime` and others do not exist.
- [ ] **Step 3:** Implement the Interfaces above. `QuickTime.at` uses `DayClock(calendar:).at(_:on:)` and `calendar.nextDay(after:)`. `inMinutes` uses `now.wholeSecond` + `n * Timing.minute`. `LiveState` decodes with `c.lenientArray(.quickReminders)` and then `.kept()`. `QuickReminder` decodes text through `QuickText.clean` and dates through `.wholeSecond`. `QuickPrefs` decodes with `known` and `value`.
- [ ] **Step 4:** Run `./scripts/test.sh SathiCoreTests`. Expected: PASS, with no other test broken.
- [ ] **Step 5:** Ask the user, then commit: `feat(core): quick reminder model, time math, and lenient storage`.

---

### Task 3: Copy

**Files:**
- Create: `Sources/SathiCore/Formatting/Copywriter+Quick.swift`
- Test: `Tests/SathiCoreTests/CopywriterQuickTests.swift`

**Interfaces:**
- Produces, all `package static` on `Copywriter`, and each takes `calendar: Calendar` for the time zone:
  - `quickEyebrow(due: Date) -> String` → "QUICK REMINDER · 2:30 PM"
  - `quickSetAt(_ created: Date) -> String` → "You set this at 11:05 AM."
  - `quickNoSnooze: String` → "No snoozes left. It stays until you tap Done."
  - `quickComesBack(text: String, at: Date) -> String` → "“Call mom” comes back at 2:35 PM". Text over `Limits.quickNoteTextMax` is cut and ends with "…".
  - `quickWhen(_ fire: Date, now: Date, showing: Bool) -> String` → "Showing now" / "in 25 min" (`Fmt.short`) / "Tomorrow"
  - `quickPreview(_ date: Date, now: Date) -> String` → "Today at 2:30 PM" / "Tomorrow at 9:00 AM"

- [ ] **Step 1:** Write 1 test per function, with the exact strings above. Use `FixedZone` for the time zone. Add 1 test for the 24-character cut: "Send the invoice to Rahim today" → "“Send the invoice to Rahi…” comes back at 2:35 PM".
- [ ] **Step 2:** Run `./scripts/test.sh CopywriterQuickTests`. Expected: FAIL.
- [ ] **Step 3:** Implement. Format times like `Copywriter.comesBack` (`Date.FormatStyle(date: .omitted, time: .shortened)` with `calendar.timeZone`).
- [ ] **Step 4:** Run the same command. Expected: PASS.
- [ ] **Step 5:** Ask the user, then commit: `feat(core): quick reminder copy`.

---

### Task 4: Engine actions, show loop, snooze, port

**Files:**
- Modify: `Sources/SathiCore/Ports/ReminderPresenter.swift` (4 methods, spec "Ports")
- Modify: `Tests/SathiTestSupport/Fakes.swift` (`SpyPresenter.Call` gets `.showQuick(UUID, Level)`, `.closeQuick(UUID)`, `.showQuickLock(UUID)`, `.showQuickSnoozed(String, Date)`)
- Modify: `Sources/SathiUI/Windows/UIController.swift`: empty bodies for the 4 methods, so the build stays green. Task 7 fills them.
- Modify: `Sources/SathiCore/Engine/Engine.swift` (1 stored property: `@Published package internal(set) var quickActivities: [UUID: QuickActivity] = [:]`)
- Modify: `Sources/SathiCore/Engine/Engine+Loop.swift` (`tick()` calls `tickQuick()` after `lockWaitingHabit()`. `upcomingDeadlines()` appends `quickDeadlines`.)
- Create: `Sources/SathiCore/Quick/QuickActivity.swift`
- Create: `Sources/SathiCore/Engine/Engine+Quick.swift` (actions and queries)
- Create: `Sources/SathiCore/Engine/Engine+QuickLoop.swift` (show, ignore, snooze, deadlines)
- Test: `Tests/SathiCoreTests/EngineQuickAddTests.swift`, `EngineQuickFireTests.swift`, `EngineQuickSnoozeTests.swift`

**Interfaces:**
- Consumes: Task 2 types, Task 3 `quickComesBack`.
- Produces (on `Engine`):
  - `package var quickReminders: [QuickReminder]` (sorted by `fireDate`)
  - `package func quick(_ id: UUID) -> QuickReminder?`
  - `package func quickDate(_ t: QuickTime) -> Date`
  - `@discardableResult package func addQuick(text: String, when: QuickTime) -> QuickAddResult`
  - `package func removeQuick(_ id: UUID)`, `package func quickDone(_ id: UUID)`, `package func snoozeQuick(_ id: UUID)`
  - `package func canSnoozeQuick(_ id: UUID) -> Bool`, `package func showsQuickClose(_ id: UUID) -> Bool`
  - `func tickQuick()`, `var quickDeadlines: [Date]`

- [ ] **Step 1: Write the failing tests**

```swift
@Test func addSavesAndSorts()            // add "B" .at(16:00), "A" .inMinutes(5) at 10:00 → quickReminders.map(\.text) == ["A","B"]; store.live.quickReminders.count == 2
@Test func addRefusesBlank()             // addQuick(text: "   ", ...) == .empty, list empty
@Test func addRefusesTwentyFirst()       // 20 adds then 1 more == .full, count 20
@Test func showsAtDueWithPing()          // .inMinutes(15); advance 14 → no .showQuick; advance 1 → calls.last == .showQuick(id, .nudge), sound.played.last == .ping
@Test func showsDuringPause()            // engine.pause(minutes: 60) then due → .showQuick
@Test func showsOnDayOff()               // every habit has today off → still .showQuick
@Test func missedTimeShowsAtLaunch()     // harness built at 11:00 with a saved item due 10:30 → .showQuick on the first tick
@Test func twoDueTogetherShowBoth()      // 2 items due 10:15 → 2 .showQuick calls; snoozeQuick(first) leaves second in quickActivities
@Test func doneRemovesAndCloses()        // quickDone → .closeQuick(id), list empty, no history event
@Test func deleteWhileShowingCloses()    // removeQuick while popup → .closeQuick(id)
@Test func snoozeComesBack()             // snoozeQuick at 10:15, snoozeMinutes 5 → .showQuickSnoozed("Call mom", 10:20); advance 5 → .showQuick(id, .persist) (Nudgy default)
@Test func ignoreCountsAsSnooze()        // ignoreMinutes 5, no answer for 5 min → snoozes == 1, .closeQuick
@Test func limitRemovesSnooze()          // snoozeLimit 1, 1 snooze → canSnoozeQuick false, showsQuickClose false, no ignore deadline (popup stays after 60 min)
@Test func closeButtonFollowsPrefs()     // quick.showsCloseButton false → showsQuickClose false at .nudge
@Test func countdownIgnoresQuick()       // a quick item due in 2 min does not change the status countdown text
@Test func noHistoryEvents()             // add, show, snooze, done → history.events empty
```

- [ ] **Step 2:** Run `./scripts/test.sh "EngineQuick"`. Expected: FAIL.
- [ ] **Step 3:** Implement. Show logic: for each reminder with `now >= fireDate` and no `quickActivities[id]`, in `fireDate` then `createdAt` order, use `EscalationPolicy.presentation(for: data.prefs.quick.strictness, snoozes:)`. For `.bubble(level)`: set `.popup(level, ignoreDeadline:)`, call `presenter.showQuick`, and play `.ping`. The ignore deadline is `now + ignoreMinutes` when a snooze is left, else `.distantFuture`. A popup with `now >= ignoreDeadline` snoozes. `snoozeQuick` saves `snoozes + 1` and `snoozedUntil` in `data.live`, removes the activity, and calls `closeQuick` and `showQuickSnoozed`. Each action calls `requestTick()`.
- [ ] **Step 4:** Run `./scripts/test.sh SathiCoreTests`. Expected: PASS.
- [ ] **Step 5:** Ask the user, then commit: `feat(core): quick reminders show at their time and come back until done`.

---

### Task 5: Levels and the shared lock

**Files:**
- Modify: `Sources/SathiCore/Engine/Engine+QuickLoop.swift` (`.lock` branch, `lockWaitingQuick()`)
- Modify: `Sources/SathiCore/Engine/Engine+Loop.swift` (`present(_:)` uses `isAnyLockShowing` in place of the `HabitID` check)
- Modify: `Sources/SathiCore/Engine/Engine+SnoozeLimit.swift` (`lockWaitingHabit()` guard uses `isAnyLockShowing`)
- Test: `Tests/SathiCoreTests/EngineQuickLevelTests.swift`, `EngineQuickLockTests.swift`

**Interfaces:**
- Consumes: Task 4.
- Produces: `var isAnyLockShowing: Bool` (a buddy is in phase `.lock` or a `quickActivities` value is `.lock`). Lock done path: `quickDone(id)` calls `presenter.closeLock()` when the activity is `.lock`.

- [ ] **Step 1: Write the failing tests**

```swift
@Test func gentleStaysNudge()            // .friendly, 3 snoozes → each show is .showQuick(id, .nudge)
@Test func nudgyPersistsAfterOne()       // .persistent: 1st .nudge, 2nd .persist
@Test func strictLocksAfterTwo()         // .strict: .nudge, .persist, then .showQuickLock(id) and sound .sosumi
@Test func lockDoneCloses()              // quickDone on lock → .closeLock, list empty
@Test func deleteWhileLockedClosesLock() // removeQuick on lock → .closeLock
@Test func quickWaitsForBuddyLock()      // water locked; quick strict reaches lock → .showQuick(id, .persist), no .showQuickLock
@Test func quickLocksWhenBuddyLockEnds() // same, with snoozeLimit 2 (no snooze left) → after water done, next tick .showQuickLock(id)
@Test func buddyWaitsForQuickLock()      // quick locked; water strict reaches lock → .showBubble(.water, .persist), no .showLock(.water)
@Test func strictLimitOneNeverLocks()    // snoozeLimit 1, .strict → stays .persist popup, never .showQuickLock
@Test func restartKeepsLevel()           // saved item snoozes 2, .strict, due → first tick .showQuickLock(id)
```

- [ ] **Step 2:** Run `./scripts/test.sh "EngineQuick"`. Expected: FAIL on the new tests.
- [ ] **Step 3:** Implement. `.lock` while `isAnyLockShowing`: show `.persist` popup. `lockWaitingQuick()` mirrors `lockWaitingHabit()`. It finds the first popup with no snooze left whose presentation is `.lock`, then calls `closeQuick`, sets `.lock`, calls `showQuickLock`, and plays `.sosumi`.
- [ ] **Step 4:** Run `./scripts/test.sh`. Expected: PASS. `EngineOneLockTests` still passes.
- [ ] **Step 5:** Ask the user, then commit: `feat(core): quick reminder levels share the one-lock rule`.

---

### Task 6: Menu card and add form

**Files:**
- Modify: `Sources/SathiUI/Theme/NightPalette.swift` (3 colors from Global Constraints)
- Create: `Sources/SathiUI/Constants/UIMetrics+Quick.swift` (`quickVisibleRows = 4` and the sizes of the design)
- Create: `Sources/SathiUI/Features/Quick/QuickListCard.swift` (header, rows, add row, form toggle)
- Create: `Sources/SathiUI/Features/Quick/QuickRow.swift`
- Create: `Sources/SathiUI/Features/Quick/QuickAddForm.swift`
- Create: `Sources/SathiUI/Features/Quick/QuickChips.swift`
- Modify: `Sources/SathiUI/Features/MenuBar/MenuPanel.swift` (card after the `SleepingRow`s; break hint under `PauseChips` when the list is not empty)
- Test: `Tests/SathiUITests/QuickListCardTests.swift`, `QuickAddFormTests.swift`, `PanelSizeTests.swift` (menu with 0, 4, and 20 items fits `UIMetrics` menu height)

**Interfaces:**
- Consumes: Task 4 Engine API, Task 3 `quickWhen` and `quickPreview`.

- [ ] **Step 1: Write the failing ViewInspector tests**
  - `emptyCardShowsOnlyAddRow`: the card has the text "Quick reminder" and no badge.
  - `rowsShowTextTimeAndWhen`: 2 items, so the badge is "2 of 20", there are 2 rows, and the first row has "in 25 min".
  - `deleteButtonRemoves`: a tap on the delete button → `engine.quickReminders` is empty.
  - `formDefaultsToFifteen`: the "15 min" chip is selected and the preview is "Today at 10:15 AM".
  - `addButtonDisabledWhenBlank`.
  - `addCallsEngine`: the text "Call mom" + "30 min" → 1 item due 10:30.
  - `timeClearsChip`: a pick of 14:37 → no chip is selected, and the preview is "Today at 2:37 PM".
  - `fullFormShowsMessage`: with 20 items, the form has the full message and no "Add reminder".
  - `breakHintOnlyWithItems`.
- [ ] **Step 2:** Run `./scripts/test.sh SathiUITests`. Expected: FAIL.
- [ ] **Step 3:** Implement to match artboards 1 and 2. Use `LazyTextField` for the text field. The form has a `.onSubmit` that adds. The time field is `DatePicker(selection:, displayedComponents: .hourAndMinute)` in `.field` style, which gives `.at(minutes:)`. The rows are in a `ScrollView` capped at `quickVisibleRows`.
- [ ] **Step 4:** Run `./scripts/test.sh` and `./scripts/lint.sh`. Expected: both PASS.
- [ ] **Step 5:** Ask the user, then commit: `feat(ui): quick reminders card and add form in the menu bar`.

---

### Task 7: Popup, snoozed note, lock, presenter

**Files:**
- Create: `Sources/SathiUI/Features/Quick/QuickPopup.swift` (artboards 3 and 4. It wiggles with `Shake` at `.persist`.)
- Create: `Sources/SathiUI/Features/Quick/QuickSnoozedNote.swift` (artboard 5. It has the same style as `SnoozedNote`.)
- Create: `Sources/SathiUI/Features/Quick/QuickLockView.swift` (the `LockShade` background, the text, `LockHoldButton` titled "Hold for Done", and a "Delete this reminder" link)
- Create: `Sources/SathiUI/Windows/UIController+Quick.swift` (the 4 port methods. `var quickPanels: [UUID: NSPanel]` goes in `UIController.swift`.)
- Modify: `Sources/SathiUI/Windows/UIController.swift`: remove the Task 4 empty bodies, and expose a lock helper that both `showLock` and `showQuickLock` use.
- Test: `Tests/SathiUITests/QuickPopupTests.swift`, `QuickLockViewTests.swift`

**Interfaces:**
- Consumes: Task 4 and Task 5 Engine API, Task 3 copy.

- [ ] **Step 1: Write the failing tests**
  - `popupShowsCopy`: the eyebrow, the text, "You set this at 11:05 AM.", "Done", and "In 5 min".
  - `popupDoneCallsEngine`: the list becomes empty.
  - `popupSnoozeCallsEngine`: `snoozes == 1`.
  - `closeHiddenAtPersist`.
  - `limitShowsOnlyDone`: no snooze button, and the `quickNoSnooze` text shows.
  - `lockHoldCallsDone`.
  - `lockDeleteRemoves`.
- [ ] **Step 2:** Run `./scripts/test.sh SathiUITests`. Expected: FAIL.
- [ ] **Step 3:** Implement. `showQuick` does `presentCorner(QuickPopup(id:level:))` and never calls `makeKey`. `showQuickSnoozed` reuses the `note` and `noteTask` slot. `showQuickLock` builds the lock windows on each screen with `QuickLockView(id:)`.
- [ ] **Step 4:** Run `./scripts/test.sh` and `./scripts/lint.sh`. Expected: both PASS.
- [ ] **Step 5:** Ask the user, then commit: `feat(ui): quick reminder corner popup, note, and lock`.

---

### Task 8: Settings card

**Files:**
- Create: `Sources/SathiUI/Features/Settings/QuickSettingsCard.swift` ("Quick reminders" title, 3 level cards, and the switch "Show a close button")
- Modify: `Sources/SathiUI/Features/Settings/GeneralTab.swift` (the card goes after the day summary)
- Modify: `Sources/SathiUI/Features/Settings/Engine+SettingsBindings.swift` (`quickStrictness: Binding<Strictness>`, `quickShowsClose: Binding<Bool>`)
- Test: `Tests/SathiUITests/QuickSettingsCardTests.swift`

- [ ] **Step 1:** Write the failing tests. `defaultIsNudgy`: the Nudgy card is selected. `pickStrictSaves`: `store.prefs.quick.strictness == .strict`. `switchSaves`: a toggle gives `showsCloseButton == false`.
- [ ] **Step 2:** Run `./scripts/test.sh QuickSettingsCardTests`. Expected: FAIL.
- [ ] **Step 3:** Implement. Reuse `StrictnessCards` with the new binding when its init takes a `Binding<Strictness>`. If it does not, add an init that does, and keep the buddy callers unchanged.
- [ ] **Step 4:** Run `./scripts/test.sh` and `./scripts/lint.sh`. Expected: both PASS.
- [ ] **Step 5:** Ask the user, then commit: `feat(ui): quick reminder level and close switch in General settings`.

---

### Task 9: Definition of done

- [ ] **Step 1:** Run `swift build -c release`. Expected: no new warnings.
- [ ] **Step 2:** Run `./build.sh --install`, then `./scripts/perf.sh`. Expected: PASS (idle CPU < 1%, memory < 40 MB, < 10 wakeups/min). Then ask the user to run `./scripts/perf.sh --windows` in Terminal with 1 quick popup open.
- [ ] **Step 3:** Do a hand test. Add a reminder for "5 min". Ignore it, snooze it, and tap Done. Do the test at Gentle, Nudgy, and Strict. Do the test during a 30 min pause.
- [ ] **Step 4:** Run the `ui-verifier` agent against the canvas artboards 1 to 5.
- [ ] **Step 5:** Update `CLAUDE.md` (the intro line, `Quick/` in the module map), `README.md`, and `docs/ROADMAP.md` (mark the phase done).
- [ ] **Step 6:** Ask the user, then commit: `docs: quick reminder in README, CLAUDE.md, and roadmap`. The website update (`/sathi-website`) and the push wait for the user.
