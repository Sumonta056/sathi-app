import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine quick add")
struct EngineQuickAddTests {
    @Test func addSavesAndSorts() {
        let h = EngineHarness()
        h.engine.addQuick(text: "B", when: .at(minutes: 16 * 60))
        h.engine.addQuick(text: "A", when: .inMinutes(5))
        #expect(h.engine.quickReminders.map(\.text) == ["A", "B"])
        #expect(h.store.live.quickReminders.count == 2)
    }

    @Test func addRefusesBlank() {
        let h = EngineHarness()
        #expect(h.engine.addQuick(text: "   ", when: .inMinutes(5)) == .empty)
        #expect(h.engine.quickReminders.isEmpty)
    }

    @Test func addRefusesTwentyFirst() {
        let h = EngineHarness()
        for i in 0 ..< Limits.quickMax {
            h.engine.addQuick(text: "n\(i)", when: .inMinutes(60))
        }
        #expect(h.engine.addQuick(text: "extra", when: .inMinutes(5)) == .full)
        #expect(h.engine.quickReminders.count == Limits.quickMax)
    }

    @Test func noHistoryEvents() {
        let h = EngineHarness()
        let id = quickID(h, "Call mom", .inMinutes(5))
        h.advance(minutes: 5)
        h.engine.snoozeQuick(id)
        h.advance(minutes: 5)
        h.engine.quickDone(id)
        #expect(h.history.appended.isEmpty)
    }

    @Test func countdownIgnoresQuick() {
        let h = EngineHarness()
        let before = h.engine.status.text
        h.engine.addQuick(text: "Soon", when: .inMinutes(2))
        h.engine.tick()
        #expect(h.engine.status.text == before)
    }
}
