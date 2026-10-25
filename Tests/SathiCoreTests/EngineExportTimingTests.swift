import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine export timing")
struct EngineExportTimingTests {
    private func target(_ name: String) throws -> URL {
        let folder = makeTempFolder()
        try makeFolder(folder)
        return folder.appendingPathComponent(name)
    }

    @Test func backupTimeIsReadAfterThePanelAndTheNameKeepsTheFirstDate() async throws {
        let h = EngineHarness(at: day(2026, 3, 4, 23, 58))
        let url = try target("backup.json")
        let spy = SpyFileExporter(url: url)
        spy.onAsk = { h.clock.advance(minutes: 5) }
        let screen = h.engine.reportScreen(.week, selected: .water)
        let outcome = await h.engine.export(.json, screen: screen, to: spy, renderer: SpySummaryRenderer())
        #expect(outcome == .saved(url))
        #expect(spy.requests.first?.suggestedName == "Sathi-backup-2026-03-04.json")
        let backup = try #require(readData(url).flatMap(DecodedBackup.decode))
        #expect(backup.exportedAt == day(2026, 3, 5, 0, 3))
    }

    @Test(arguments: [ExportFormat.csv, .json])
    func historyIsReadOffTheMainThread(_ format: ExportFormat) async throws {
        let history = ThreadSpyHistoryStore(events: [.done(.water, 1, at: day(2026, 3, 3, 9))])
        let clock = FakeClock(day(2026, 3, 4, 10))
        let engine = Engine(
            store: InMemoryStateStore(),
            history: history,
            clock: clock,
            sound: SpySoundPlayer(),
            presenter: SpyPresenter()
        )
        let url = try target("out")
        let screen = engine.reportScreen(.week, selected: .water)
        let outcome = await engine.export(format, screen: screen, to: SpyFileExporter(url: url), renderer: SpySummaryRenderer())
        #expect(outcome == .saved(url))
        #expect(history.allEventsOnMain == [false])
    }
}
