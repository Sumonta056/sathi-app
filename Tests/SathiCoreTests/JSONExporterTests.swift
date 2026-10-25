import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("JSONExporter")
struct JSONExporterTests {
    private let utc = FixedZone("UTC")

    private var prefs: Prefs {
        var p = Prefs()
        p.general.name = "Asha"
        p.water.dailyGoalGlasses = 10
        p.meditation.enabled = true
        p.meditation.dailyGoalMinutes = 20
        return p
    }

    private var live: LiveState {
        var l = LiveState()
        l.bottleLevel = 0.5
        l.lastWaterDone = utc.date(2026, 3, 4, 8)
        l.streakReset = [HabitID.water.rawValue: utc.date(2026, 3, 1, 7)]
        return l
    }

    private var events: [HistoryEvent] {
        [
            .done(.water, 0.25, at: utc.date(2026, 2, 1, 9)),
            .snooze(.reading, at: utc.date(2026, 3, 3, 22)),
            .skip(.water, at: utc.date(2026, 3, 4, 7))
        ]
    }

    private func backup() -> Data {
        JSONExporter.backup(prefs: prefs, live: live, events: events, exportedAt: utc.date(2026, 3, 4, 9))
    }

    @Test func decodesBackToTheSameValues() throws {
        let decoded = try #require(DecodedBackup.decode(backup()))
        #expect(decoded.prefs == prefs)
        #expect(decoded.live == live)
        #expect(decoded.events == events)
        #expect(decoded.exportedAt == utc.date(2026, 3, 4, 9))
    }

    @Test func schemaVersionIsOne() throws {
        #expect(try #require(DecodedBackup.decode(backup())).schemaVersion == 1)
    }

    @Test func datesAreISO8601AndKeysAreSorted() throws {
        let text = try #require(String(data: backup(), encoding: .utf8))
        #expect(text.contains("\"exportedAt\":\"2026-03-04T09:00:00Z\""))
        let keys = ["\"events\"", "\"exportedAt\"", "\"live\"", "\"prefs\"", "\"schemaVersion\""]
        let positions = keys.compactMap { text.range(of: $0)?.lowerBound }
        #expect(positions.count == keys.count)
        #expect(positions == positions.sorted())
    }

    @Test func emptyHistoryStillDecodes() throws {
        let data = JSONExporter.backup(prefs: Prefs(), live: LiveState(), events: [], exportedAt: utc.date(2026, 3, 4))
        let decoded = try #require(DecodedBackup.decode(data))
        #expect(decoded.events.isEmpty)
        #expect(decoded.prefs == Prefs())
    }
}
