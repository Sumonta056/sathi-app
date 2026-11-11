import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Status label")
struct StatusLabelTests {
    @Test func statusLabelShowsTheStatusText() throws {
        let h = EngineHarness()
        let sut = StatusLabel(status: h.engine.status)
        #expect(try sut.inspect().find(text: "2h 0m") != nil)
    }

    @Test func statusIconIsCachedPerLevel() {
        #expect(StatusIcon.image(level: 0.5) === StatusIcon.image(level: 0.5))
        #expect(StatusIcon.image(level: 0.5).isTemplate)
    }
}
