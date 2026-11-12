import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Tracker reports wiring")
struct TrackerReportsWiringTests {
    private let noon = day(2026, 3, 4, 12)

    private func harness() -> EngineHarness {
        let item = Activity(text: "Fix login bug", category: "Coding", start: day(2026, 3, 4, 9), end: day(2026, 3, 4, 10))
        return EngineHarness.tracker(at: noon, activities: [item])
    }

    @Test func activitiesPageShowsTodaysLogFromTheEngine() throws {
        let h = harness()
        let sut = try ActivitiesPage().environmentObject(h.engine).inspect()
        #expect(MenuFind.hasText(sut, containing: "Fix login bug"))
        #expect(throws: Never.self) { try Find.button(sut, holding: Copywriter.rangeSegment(.month)) }
    }

    @Test func exportWritesTheRangeCSV() {
        let h = harness()
        let folder = makeTempFolder()
        let url = h.engine.exportActivities(h.engine.currentRange(.day), to: folder).url
        #expect(url.map(fileExists) == true)
        try? FileManager.default.removeItem(at: folder)
    }
}
