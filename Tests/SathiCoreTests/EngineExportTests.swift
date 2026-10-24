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

    @Test func csvExportSavesAllHistoryWithTheHistoryName() throws {
        let h = harness()
        let spy = SpyFileExporter()
        #expect(h.engine.export(.csv, to: spy))
        let save = try #require(spy.saves.first)
        #expect(spy.saves.count == 1)
        #expect(save.suggestedName == "Sathi-history-2026-03-04.csv")
        #expect(save.format == .csv)
        let lines = try #require(String(data: save.data, encoding: .utf8)).split(separator: "\n").map(String.init)
        #expect(lines.count == 3)
        #expect(lines.first == "timestamp,habit,kind,amount")
        #expect(lines.dropFirst().first?.hasSuffix(",water,done,1") == true)
        #expect(lines.last?.hasSuffix(",reading,snooze,0") == true)
        #expect(h.history.allEventsCalls == 1)
    }

    @Test func jsonExportSavesAFullBackupWithTheBackupName() throws {
        let h = harness()
        h.clock.advance(minutes: 7)
        let spy = SpyFileExporter()
        #expect(h.engine.export(.json, to: spy))
        let save = try #require(spy.saves.first)
        #expect(save.suggestedName == "Sathi-backup-2026-03-04.json")
        #expect(save.format == .json)
        let backup = try #require(DecodedBackup.decode(save.data))
        #expect(backup.schemaVersion == 1)
        #expect(backup.exportedAt == day(2026, 3, 4, 10, 7))
        #expect(backup.prefs == h.engine.data.prefs)
        #expect(backup.live == h.engine.data.live)
        #expect(backup.events == [old, recent])
    }

    @Test(arguments: [ExportFormat.csv, .json])
    func theExporterResultPassesThrough(_ format: ExportFormat) {
        let h = harness()
        let spy = SpyFileExporter()
        spy.result = false
        #expect(!h.engine.export(format, to: spy))
        #expect(spy.saves.count == 1)
    }

    @Test func theFileNameUsesTheClockDate() {
        let h = harness()
        h.clock.advance(minutes: 15 * 60)
        let spy = SpyFileExporter()
        _ = h.engine.export(.csv, to: spy)
        #expect(spy.saves.first?.suggestedName == "Sathi-history-2026-03-05.csv")
    }
}
