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

    @Test func activitiesTabShowsTodaysLogFromTheEngine() throws {
        let h = harness()
        let sut = try ReportsView().environmentObject(h.engine).inspect()
        #expect(throws: Never.self) { try sut.find(text: Copywriter.trackerTimeline) }
        #expect(MenuFind.hasText(sut, containing: "Fix login bug"))
        #expect(throws: Never.self) { try Find.button(sut, holding: Copywriter.trackerRangeMonth) }
    }

    @Test func exportMonthWritesBothFilesAndShowsThemInFinder() {
        let h = harness()
        let folder = makeTempFolder()
        var shown: [URL] = []
        ActivityMonthExport.run(h.engine, month: MonthKey(noon, calendar: .current), folder: folder) { shown = $0 }
        #expect(Set(shown.map(\.pathExtension)) == ["csv", "json"])
        #expect(shown.allSatisfy(fileExists))
        try? FileManager.default.removeItem(at: folder)
    }
}
