import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Status label time block")
struct StatusLabelBlockTests {
    private func iconNames(_ h: EngineHarness) throws -> [String] {
        let sut = try StatusLabel(status: h.engine.status).inspect()
        return sut.findAll(ViewType.Image.self).compactMap { try? $0.actualImage().name() }
    }

    @Test func noBlockMeansNoBlockFlag() {
        #expect(!Block.harness().engine.status.isBlock)
    }

    @Test func runningBlockSetsTheFlagAndShowsTheTimerIcon() throws {
        let h = Block.running(.minutes(30), after: 18)
        #expect(h.engine.status.isBlock)
        #expect(try iconNames(h).contains("timer"))
        #expect(try StatusLabel(status: h.engine.status).inspect().find(text: "12m") != nil)
    }

    @Test func openBlockSetsTheFlag() {
        let h = Block.running(.open, after: 5)
        #expect(h.engine.status.isBlock)
    }

    @Test func endingTheBlockClearsTheFlagAndIcon() throws {
        let h = Block.running(.minutes(30), after: 18)
        #expect(h.engine.status.isBlock)
        h.engine.endBlock()
        h.engine.tick()
        #expect(!h.engine.status.isBlock)
        #expect(try !iconNames(h).contains("timer"))
    }
}
