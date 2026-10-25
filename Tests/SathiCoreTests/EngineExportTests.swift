import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine export")
struct EngineExportTests {
    private let old = HistoryEvent.done(.water, 1, at: day(2025, 6, 1, 9))
    private let recent = HistoryEvent.snooze(.reading, at: day(2026, 3, 3, 22))

    private func harness() -> EngineHarness {
        EngineHarness {
            $0.events = [recent, old]
            $0.prefs.general.name = "Asha"
            $0.live.bottleLevel = 0.5
        }
    }

    private func target(_ name: String) throws -> URL {
        let folder = makeTempFolder()
        try makeFolder(folder)
        return folder.appendingPathComponent(name)
    }

    private func export(
        _ h: EngineHarness,
        _ format: ExportFormat,
        _ spy: SpyFileExporter,
        _ renderer: SpySummaryRenderer? = nil
    ) async -> ExportOutcome {
        await h.engine.export(format, screen: h.engine.reportScreen(.week, selected: .water), to: spy, renderer: renderer ?? SpySummaryRenderer())
    }

    @Test(arguments: ExportFormat.allCases)
    func aCancelledDestinationWritesNothingAndReadsNoHistory(_ format: ExportFormat) async {
        let h = harness()
        h.history.clearRanges()
        let renderer = SpySummaryRenderer(result: Data("%PDF".utf8))
        let spy = SpyFileExporter(url: nil)
        let outcome = await export(h, format, spy, renderer)
        #expect(outcome == .cancelled)
        #expect(spy.requests.count == 1)
        #expect(h.history.allEventsCalls == 0)
        #expect(renderer.screens.isEmpty)
    }

    @Test func csvExportWritesAllHistoryAfterAskingWithTheHistoryName() async throws {
        let h = harness()
        let url = try target("history.csv")
        let spy = SpyFileExporter(url: url)
        #expect(await export(h, .csv, spy) == .saved(url))
        #expect(spy.requests == [SpyFileExporter.Request(suggestedName: "Sathi-history-2026-03-04.csv", format: .csv)])
        let lines = try #require(readText(url)).split(separator: "\n").map(String.init)
        #expect(lines.count == 3)
        #expect(lines.first == "timestamp,habit,kind,amount")
        #expect(lines.dropFirst().first?.hasSuffix(",water,done,1") == true)
        #expect(lines.last?.hasSuffix(",reading,snooze,0") == true)
        #expect(h.history.allEventsCalls == 1)
    }

    @Test func jsonExportWritesAFullBackupWithTheBackupName() async throws {
        let h = harness()
        h.clock.advance(minutes: 7)
        let url = try target("backup.json")
        let spy = SpyFileExporter(url: url)
        #expect(await export(h, .json, spy) == .saved(url))
        #expect(spy.requests.first?.suggestedName == "Sathi-backup-2026-03-04.json")
        #expect(spy.requests.first?.format == .json)
        let data = try #require(readData(url))
        let backup = try #require(DecodedBackup.decode(data))
        #expect(backup.schemaVersion == 1)
        #expect(backup.exportedAt == day(2026, 3, 4, 10, 7))
        #expect(backup.prefs == h.engine.data.prefs)
        #expect(backup.live == h.engine.data.live)
        #expect(backup.events == [old, recent])
    }

    @Test func pdfExportWritesTheRenderedDataOfTheScreen() async throws {
        let h = harness()
        let url = try target("summary.pdf")
        let spy = SpyFileExporter(url: url)
        let pdf = Data("%PDF-1.4 summary".utf8)
        let renderer = SpySummaryRenderer(result: pdf)
        let screen = h.engine.reportScreen(.month, selected: .reading)
        let outcome = await h.engine.export(.pdf, screen: screen, to: spy, renderer: renderer)
        #expect(outcome == .saved(url))
        #expect(spy.requests == [SpyFileExporter.Request(suggestedName: "Sathi-summary-2026-03-04.pdf", format: .pdf)])
        #expect(renderer.screens == [screen])
        #expect(readData(url) == pdf)
    }

    @Test func aFailedRenderReturnsFailedAndWritesNoFile() async throws {
        let h = harness()
        let url = try target("summary.pdf")
        let renderer = SpySummaryRenderer(result: nil)
        #expect(await export(h, .pdf, SpyFileExporter(url: url), renderer) == .failed)
        #expect(renderer.screens.count == 1)
        #expect(!fileExists(url))
    }

    @Test(arguments: ExportFormat.allCases)
    func aWriteIntoAMissingFolderFails(_ format: ExportFormat) async {
        let h = harness()
        let url = makeTempFolder().appendingPathComponent("missing").appendingPathComponent("out")
        let renderer = SpySummaryRenderer(result: Data("%PDF".utf8))
        #expect(await export(h, format, SpyFileExporter(url: url), renderer) == .failed)
        #expect(!fileExists(url))
    }

    @Test func theFileNameUsesTheClockDate() async {
        let h = harness()
        h.clock.advance(minutes: 15 * 60)
        let spy = SpyFileExporter(url: nil)
        _ = await export(h, .csv, spy)
        #expect(spy.requests.first?.suggestedName == "Sathi-history-2026-03-05.csv")
    }

    @Test func exportsWriteOverAnExistingFile() async throws {
        let h = harness()
        let url = try target("history.csv")
        try writeText("old", to: url)
        #expect(await export(h, .csv, SpyFileExporter(url: url)) == .saved(url))
        #expect(readText(url)?.hasPrefix("timestamp,habit,kind,amount") == true)
    }
}
