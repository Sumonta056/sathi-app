import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("ExportJob")
struct ExportJobTests {
    private let zone = FixedZone.berlin
    private var event: HistoryEvent { .done(.water, 2, at: zone.date(2026, 3, 4, 9)) }

    private func job() -> ExportJob {
        ExportJob(
            history: InMemoryHistoryStore(events: [event]),
            prefs: Prefs(),
            live: LiveState(),
            exportedAt: zone.date(2026, 3, 4, 10),
            timeZone: zone.timeZone
        )
    }

    private func target(_ name: String) throws -> URL {
        let folder = makeTempFolder()
        try makeFolder(folder)
        return folder.appendingPathComponent(name)
    }

    @Test func pdfIsNeverWrittenByAJob() throws {
        let url = try target("summary.pdf")
        #expect(job().write(.pdf, to: url) == .failed)
        #expect(!fileExists(url))
    }

    @Test func csvWritesOneRowPerEvent() throws {
        let url = try target("history.csv")
        #expect(job().write(.csv, to: url) == .saved(url))
        #expect(readText(url) == "timestamp,habit,kind,amount\n2026-03-04T09:00:00+01:00,water,done,2\n")
    }

    @Test func jsonWritesABackupWithTheJobTime() throws {
        let url = try target("backup.json")
        #expect(job().write(.json, to: url) == .saved(url))
        let data = try #require(readData(url))
        let backup = try #require(DecodedBackup.decode(data))
        #expect(backup.exportedAt == zone.date(2026, 3, 4, 10))
        #expect(backup.events == [event])
    }

    @Test(arguments: [ExportFormat.csv, .json])
    func aMissingFolderFails(_ format: ExportFormat) {
        let url = makeTempFolder().appendingPathComponent("missing").appendingPathComponent("out")
        #expect(job().write(format, to: url) == .failed)
    }
}
