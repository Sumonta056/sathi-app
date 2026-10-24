import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Nap banner")
struct NapBannerTests {
    private func banner(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(NapBanner(), h).inspect()
    }

    @Test func restOfDaySaysTomorrow() throws {
        let h = EngineHarness()
        h.engine.pauseRestOfDay()
        let sut = try banner(h)
        #expect(throws: Never.self) { try sut.find(text: "Buddies are napping until tomorrow") }
    }

    @Test func shortPauseShowsTheEndTime() throws {
        let h = EngineHarness()
        h.engine.pause(hours: 1)
        let time = day(2026, 3, 4, 11).formatted(date: .omitted, time: .shortened)
        #expect(throws: Never.self) { try banner(h).find(text: "Buddies are napping until \(time)") }
    }
}
