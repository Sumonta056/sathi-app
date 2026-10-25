---
name: write-unit-tests
description: How to write unit and UI tests for Sathi with Swift Testing, the EngineHarness fakes, and ViewInspector. Use when adding or fixing tests, when a source file has no test, or when the test-writer agent starts.
---

# Write tests for Sathi

Every example below is adapted from a real test. The source is named above each example.

## Pick the file

Use the table in `.claude/rules/testing.md`. Add to the existing suite when one fits. Create `<Name>Tests.swift` otherwise.

## Core logic (pure)

From `WaterRulesTests` and `FmtTests`:

```swift
@Suite("WaterRules")
struct WaterRulesTests {
    private let rules = WaterRules(prefs: Prefs())

    @Test func nextDueAfterEndMovesToNextMorning() {
        let next = rules.nextDue(now: day(2026, 3, 4, 17), lastDone: day(2026, 3, 4, 17), doneToday: 0, skipToday: false)
        #expect(next == day(2026, 3, 5, 9, 30))
    }

    @Test(arguments: [(-5.0, "now"), (90.0, "1m"), (5430.0, "1h 30m")])
    func short(_ value: TimeInterval, _ expected: String) {
        #expect(Fmt.short(value) == expected)
    }
}
```

## Engine flows

From `EngineFlowTests.strictWaterEscalatesToLock`:

```swift
@MainActor
@Suite("Engine flows")
struct EngineFlowTests {
    @Test func strictWaterEscalatesToLock() {
        let h = EngineHarness()
        h.showReminder(.water)
        h.engine.snooze()
        h.advance(minutes: 5)
        #expect(h.engine.phase == .bubble(.water, .persist))
        h.engine.snooze()
        h.advance(minutes: 5)
        #expect(h.engine.phase == .lock(.water))
        #expect(h.presenter.calls.last == .showLock(.water))
    }
}
```

- `EngineHarness` starts at 2026-03-04 10:00 (inside water hours). Water is due at 12:00. Reading is due at 22:00.
- Configure the start data in the closure: `EngineHarness { $0.prefs.general.soundOn = false }`. The closure gets a `Persisted` (`prefs`, `live`, `events`).
- To have water due at a given time, set `$0.live.lastWaterDone`.
- `h.advance(minutes:)` moves the fake clock and calls `tick()`.
- Read per-habit state with `h.engine.state(.water)`. Read saves with `h.store.prefs`, `h.store.live`, and `h.history.appended`.

## UI (ViewInspector)

From `BubbleViewTests.readingBubbleStartsTheTimer`:

```swift
@MainActor
@Suite("Bubble")
struct BubbleViewTests {
    @Test func readingBubbleStartsTheTimer() throws {
        let h = EngineHarness()
        h.showReminder(.reading)
        let sut = BubbleView(id: .reading, level: .nudge).environmentObject(h.engine)
        try sut.inspect().find(button: "Start 15-min timer").tap()
        #expect(h.engine.phase == .session(.reading))
    }
}
```

- UI tests import `@testable import SathiUI`, `SwiftUI`, and `ViewInspector`.
- To tap a custom button with a complex label: `find(text: "Half").find(ViewType.Button.self, relation: .parent).tap()`.
- ViewInspector does not run `onAppear`. It does not re-render `@State` after a tap. Re-inspect only state that lives in `Engine`.

## Files in a temp folder

From `FileStateStoreTests`. Use the helpers in `Tests/SathiTestSupport/TestFiles.swift`.

```swift
@Suite("FileStateStore")
struct FileStateStoreTests {
    private let base = makeTempFolder()
    private var prefsURL: URL { base.appendingPathComponent("prefs.json") }

    @Test func noFileIsWrittenBeforeFlush() {
        let store = FileStateStore(base: base, delay: 3600)
        store.savePrefs(customPrefs)
        #expect(!fileExists(prefsURL))
        store.flush()
        #expect(fileExists(prefsURL))
    }
}
```

- Each test gets a new folder from `makeTempFolder()`. Never use the real Application Support folder.
- Pass `delay: 3600` so that only `flush()` writes. Call `flush()` before you read the file back.
- Check a round trip with a second store on the same folder: `FileStateStore(base: base).loadPrefs()`.
- Read raw files with `readJSONObject`, `readText`, or `readData`. Write bad files with `writeText`.

## Permission failures

From `FileStateStoreFailureTests.failedSaveIsKeptAndWrittenByTheNextFlush`:

```swift
@Test func failedSaveIsKeptAndWrittenByTheNextFlush() throws {
    try makeFolder(base)
    defer { try? setPermissions(0o700, base) }
    let s = store()
    try setPermissions(0o500, base)
    s.savePrefs(prefs(named: "First"))
    #expect(!s.flush())
    s.savePrefs(prefs(named: "Last"))
    try setPermissions(0o700, base)
    #expect(s.flush())
    #expect(store().loadPrefs() == prefs(named: "Last"))
}
```

- Set the `defer` restore right after the folder or file exists, before you remove a permission. Otherwise the temp folder cannot be deleted.
- `0o500` on a folder blocks writes. `0o000` on a file blocks reads.
- To prove "never overwrite", keep the bytes with `readData` before, then compare after (see `unreadablePrefsFileIsNeverOverwritten`).
- To prove "retry", assert that `flush()` returns `false`, restore the permission, then assert that the next `flush()` returns `true`.

## History and export fakes

`InMemoryHistoryStore`, from `GregorianTests.streakAcrossAMonthBoundaryWorksWithABuddhistCalendar`:

```swift
let now = zone.date(2026, 4, 3, 12)
let store = InMemoryHistoryStore(events: zone.doneDays(.water, 8, count: 10, endingAt: now))
let streak = StreakCalculator(calendar: buddhist)
    .current(.water, goal: 8, reset: nil, now: now) { store.events(from: $0.start, to: $0.end) }
#expect(streak == 10)
```

- It records what the code asks for: `appended`, `ranges`, `allEventsCalls`, `flushes`. Call `clearRanges()` to reset `ranges`.
- Set `failFlush = true` to simulate a failed write. `InMemoryStateStore` has the same flag.

`SpyFileExporter`, from `EngineExportTests.aCancelledDestinationWritesNothingAndReadsNoHistory`:

```swift
@Test(arguments: ExportFormat.allCases)
func aCancelledDestinationWritesNothingAndReadsNoHistory(_ format: ExportFormat) async {
    let h = harness()
    h.history.clearRanges()
    let spy = SpyFileExporter(url: nil)
    let outcome = await h.engine.export(format, screen: h.engine.reportScreen(.week, selected: .water), to: spy, renderer: SpySummaryRenderer())
    #expect(outcome == .cancelled)
    #expect(spy.requests.count == 1)
    #expect(h.history.allEventsCalls == 0)
}
```

- `SpyFileExporter(url: nil)` is a cancel. Give it a URL in a temp folder to test a save.
- `spy.requests` holds each `suggestedName` and `format`. Use `onAsk` to act while the panel is "open".
- Decode a JSON backup with `DecodedBackup.decode(_:)`.

## Dates and time zones

From `ExportNamesTests.theDateIsTheDateOfTheCalendarZone`:

```swift
@Suite("ExportNames")
struct ExportNamesTests {
    private let zone = FixedZone.berlin

    @Test func theDateIsTheDateOfTheCalendarZone() {
        let lateEvening = FixedZone("America/New_York").date(2026, 3, 3, 23)
        #expect(ExportNames.fileName(.csv, on: lateEvening, calendar: zone.calendar) == "Sathi-history-2026-03-04.csv")
    }
}
```

- `day()` and `EngineHarness` use `Calendar.current`. Use them only when the time zone does not change the result.
- For day starts, DST, month edges, and file names, use `FixedZone` (`.berlin`, `.newYork`, `.cairo`). Never the system time zone.
- Pass `zone.calendar` to the code under test. Build dates with `zone.date(...)`. Check wall-clock values with `zone.wallClock(_:)`.
- To prove Gregorian dates, pass `FixedZone("Europe/Berlin", calendar: .buddhist).calendar` (see `GregorianTests`).

## Check your test

1. Run it: `./scripts/test.sh "<Suite name>"`.
2. Break the code on purpose (flip a condition). The test must fail. Undo the change.
3. No `sleep`, no `Date()`, no real windows, no real sounds.
4. No comments.
