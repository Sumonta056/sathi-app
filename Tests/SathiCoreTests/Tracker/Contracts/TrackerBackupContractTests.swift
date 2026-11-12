import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Tracker backup contract")
struct TrackerBackupContractTests {
    private let utc = FixedZone("UTC")
    private let items: [Activity]

    init() {
        let start = FixedZone("UTC").date(2026, 11, 9, 9)
        items = [
            Activity(text: "Standup", category: "Meeting", start: start, end: start.addingTimeInterval(1200)),
            Activity(kind: .away, text: "", start: start.addingTimeInterval(1200), end: start.addingTimeInterval(3000), awayPlace: .walk)
        ]
    }

    @Test func backupHoldsTheActivities() throws {
        let data = JSONExporter.backup(prefs: Prefs(), live: LiveState(), events: [], activities: items, exportedAt: utc.date(2026, 11, 9))
        let decoded = try #require(DecodedBackup.decode(data))
        #expect(decoded.activities == items)
    }

    @Test func oldCallersStillWriteAnEmptyList() throws {
        let data = JSONExporter.backup(prefs: Prefs(), live: LiveState(), events: [], exportedAt: utc.date(2026, 11, 9))
        #expect(try #require(DecodedBackup.decode(data)).activities == [])
    }

    @Test func exportJobReadsTheActivityStore() throws {
        let store = InMemoryActivityStore(activities: items, calendar: utc.calendar)
        let job = ExportJob(
            history: InMemoryHistoryStore(),
            prefs: Prefs(),
            live: LiveState(),
            exportedAt: utc.date(2026, 11, 9),
            timeZone: utc.timeZone,
            activities: store
        )
        let url = makeTempFolder().appendingPathExtension("json")
        #expect(job.write(.json, to: url) == .saved(url))
        let data = try #require(readData(url))
        let decoded = try #require(DecodedBackup.decode(data))
        #expect(decoded.activities == items)
    }
}
