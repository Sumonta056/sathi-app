import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Tracker export month")
struct TrackerExportMonthTests {
    @Test func writesJSONAndCSVForTheMonthIntoTheFolder() throws {
        let item = Activity(text: "Code review", category: "Coding", start: wed(9), end: wed(10))
        let h = EngineHarness.tracker(at: wed(12), activities: [item])
        let folder = makeTempFolder()
        let month = MonthKey(wed(9), calendar: .current)
        let urls = h.engine.exportActivityMonth(month, to: folder)
        #expect(urls.map(\.lastPathComponent).sorted() == [
            ActivityMonthExporter.fileName(month, format: .csv),
            ActivityMonthExporter.fileName(month, format: .json)
        ].sorted())
        #expect(urls.allSatisfy(fileExists))
        let csv = try #require(urls.first { $0.pathExtension == "csv" })
        #expect(readText(csv)?.contains("Code review") == true)
        try? FileManager.default.removeItem(at: folder)
    }

    @Test func aFolderThatCannotBeWrittenGivesNoFiles() {
        let h = EngineHarness.tracker(at: wed(12))
        let urls = h.engine.exportActivityMonth(MonthKey(wed(9), calendar: .current), to: URL(fileURLWithPath: "/dev/null/nope"))
        #expect(urls.isEmpty)
    }
}
