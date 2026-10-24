---
name: write-unit-tests
description: How to write unit and UI tests for Sathi with Swift Testing, the EngineHarness fakes, and ViewInspector. Use when adding or fixing tests, when a source file has no test, or when the test-writer agent starts.
---

# Write tests for Sathi

## Pick the file

Use the table in `.claude/rules/testing.md`. Add to the existing suite when one fits. Create `<Name>Tests.swift` otherwise.

## Core logic (pure)

```swift
import SathiCore
import SathiTestSupport
import Testing

@Suite("Scheduler")
struct SchedulerTests {
    private let s = Scheduler(prefs: Prefs())

    @Test func nextWaterDueAfterEndMovesToNextMorning() {
        #expect(s.nextWaterDue(after: day(2026, 3, 4, 17)) == day(2026, 3, 5, 9, 30))
    }

    @Test(arguments: [(0, "now"), (90, "1m")])
    func short(_ seconds: Double, _ expected: String) {
        #expect(Fmt.short(seconds) == expected)
    }
}
```

## Engine flows

```swift
@MainActor
@Suite("Engine flows")
struct EngineFlowTests {
    @Test func strictWaterEscalatesToLock() {
        let h = EngineHarness { $0.prefs.waterStrictness = .strict }
        h.showReminder(.water)
        h.engine.snooze(); h.advance(minutes: 5)
        h.engine.snooze(); h.advance(minutes: 5)
        #expect(h.engine.phase == .lock(.water))
        #expect(h.presenter.calls.last == .showLock(.water))
    }
}
```

- `EngineHarness` starts at 2026-03-04 10:00 (inside water hours). Water is due at 12:00. Reading is due at 22:00.
- To have water due at a given time, set `$0.lastWaterDone`.
- `h.advance(minutes:)` moves the fake clock and calls `tick()`.

## UI (ViewInspector)

```swift
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Bubble")
struct BubbleViewTests {
    @Test func snoozeButtonSnoozes() throws {
        let h = EngineHarness()
        h.showReminder(.water)
        let sut = BubbleView(id: .water, level: .nudge).environmentObject(h.engine)
        try sut.inspect().find(button: "Snooze 5 min").tap()
        #expect(h.engine.water.snoozes == 1)
    }
}
```

- To tap a custom button with a complex label: `find(text: "Half").find(ViewType.Button.self, relation: .parent).tap()`.
- ViewInspector does not run `onAppear`. It does not re-render `@State` after a tap. Re-inspect only state that lives in `Engine`.

## Check your test

1. Run it: `./scripts/test.sh "<Suite name>"`.
2. Break the code on purpose (flip a condition). The test must fail. Undo the change.
3. No `sleep`, no `Date()`, no real windows, no real sounds.
4. No comments.
