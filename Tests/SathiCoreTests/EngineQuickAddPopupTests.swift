import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine quick add popup")
struct EngineQuickAddPopupTests {
    @Test func openQuickAddShowsTheAddPopup() {
        let h = EngineHarness()
        h.engine.openQuickAdd()
        #expect(h.presenter.calls.last == .showQuickAdd)
    }

    @Test func closeQuickAddClosesTheAddPopup() {
        let h = EngineHarness()
        h.engine.openQuickAdd()
        h.engine.closeQuickAdd()
        #expect(h.presenter.calls.last == .closeQuickAdd)
    }

    @Test func addingAReminderClosesTheAddPopup() {
        let h = EngineHarness()
        h.engine.openQuickAdd()
        _ = h.engine.addQuick(text: "Call mom", when: .inMinutes(15))
        #expect(h.engine.quickReminders.count == 1)
        #expect(h.presenter.calls.contains(.closeQuickAdd))
    }

    @Test func blankTextKeepsTheAddPopupOpen() {
        let h = EngineHarness()
        h.engine.openQuickAdd()
        _ = h.engine.addQuick(text: "   ", when: .inMinutes(15))
        #expect(!h.presenter.calls.contains(.closeQuickAdd))
    }
}
