import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Quick lock view")
struct QuickLockViewTests {
    private func setup() -> (EngineHarness, UUID) {
        let item = Quick.item("Call mom", minutes: 0)
        return (Quick.harness([item]), item.id)
    }

    @Test func lockShowsTextAndHold() throws {
        let (h, id) = setup()
        let sut = try hosted(QuickLockView(id: id), h).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Call mom") }
        #expect(throws: Never.self) { try sut.find(text: "Hold for Done") }
        #expect(throws: Never.self) { try sut.find(button: "Delete this reminder") }
    }

    @Test func lockDeleteRemoves() throws {
        let (h, id) = setup()
        try hosted(QuickLockView(id: id), h).inspect().find(button: "Delete this reminder").tap()
        #expect(h.engine.quickReminders.isEmpty)
    }

    @Test func lockHoldCallsDone() {
        let (h, id) = setup()
        QuickLockView.confirm(id, engine: h.engine)
        #expect(h.engine.quickReminders.isEmpty)
    }
}
