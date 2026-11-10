import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@Suite("Tracker backup with FileActivityStore")
struct TrackerBackupStoreTests {
    private let base = makeTempFolder()
    private let zone = FixedZone("UTC")

    @Test func theJSONBackupIncludesEveryActivityMonth() throws {
        let store = FileActivityStore(base: base, delay: 3600)
        let oct = try #require(MonthKey(year: 2026, month: 10))
        let nov = try #require(MonthKey(year: 2026, month: 11))
        let a = Activity(text: "Old", start: zone.date(2026, 10, 30, 9), end: zone.date(2026, 10, 30, 10))
        let b = Activity(text: "New", start: zone.date(2026, 11, 2, 9), end: zone.date(2026, 11, 2, 10))
        store.save(ActivityMonth(key: nov, items: [b]))
        store.save(ActivityMonth(key: oct, items: [a]))
        store.flush()
        let job = ExportJob(
            history: InMemoryHistoryStore(),
            prefs: Prefs(),
            live: LiveState(),
            exportedAt: zone.date(2026, 11, 10, 8),
            timeZone: zone.timeZone,
            activities: FileActivityStore(base: base, delay: 3600)
        )
        let out = base.appendingPathComponent("backup.json")
        #expect(job.write(.json, to: out) == .saved(out))
        let json = try #require(readJSONObject(out))
        let items = try #require(json["activities"] as? [[String: Any]])
        #expect(items.map { $0["text"] as? String } == ["Old", "New"])
    }
}
