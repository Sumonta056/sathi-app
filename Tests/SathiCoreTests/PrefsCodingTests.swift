import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Prefs coding")
struct PrefsCodingTests {
    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: Data(json.utf8))
    }

    private func roundTrip<T: Codable>(_ value: T) throws -> T {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: encoder.encode(value))
    }

    private var customPrefs: Prefs {
        var p = Prefs()
        p.general.name = "Asha"
        p.general.snoozeMinutes = 10
        p.water.intervalMinutes = 90
        p.water.container = .bottle
        p.water.bottleSizeGlasses = 4.5
        p.reading.enabled = false
        p.reading.strictness = .friendly
        return p
    }

    @Test func prefsRoundTrip() throws {
        #expect(try roundTrip(customPrefs) == customPrefs)
    }

    @Test func liveStateRoundTrip() throws {
        var live = LiveState()
        live.bottleLevel = 0.4
        live.lastWaterDone = day(2026, 1, 2, 10)
        live.streakReset = [HabitID.water.rawValue: day(2026, 1, 1, 9)]
        #expect(try roundTrip(live) == live)
    }

    @Test func historyEventRoundTrip() throws {
        let events: [HistoryEvent] = [
            .done(.water, 1.5, at: day(2026, 1, 2, 10)),
            .snooze(.reading, at: day(2026, 1, 2, 22)),
            .skip(.water, at: day(2026, 1, 3, 11))
        ]
        #expect(try roundTrip(events) == events)
    }

    @Test func emptyJSONDecodesToDefaults() throws {
        #expect(try decode(Prefs.self, "{}") == Prefs())
        #expect(try decode(GeneralPrefs.self, "{}") == GeneralPrefs())
        #expect(try decode(WaterPrefs.self, "{}") == WaterPrefs())
        #expect(try decode(ReadingPrefs.self, "{}") == ReadingPrefs())
        #expect(try decode(LiveState.self, "{}") == LiveState())
    }

    @Test func oneKnownKeyKeepsTheOtherDefaults() throws {
        var expected = Prefs()
        expected.water.intervalMinutes = 60
        #expect(try decode(Prefs.self, #"{"water":{"intervalMinutes":60}}"#) == expected)

        var general = GeneralPrefs()
        general.name = "Asha"
        #expect(try decode(GeneralPrefs.self, #"{"name":"Asha"}"#) == general)

        var reading = ReadingPrefs()
        reading.sessionMinutes = 30
        #expect(try decode(ReadingPrefs.self, #"{"sessionMinutes":30}"#) == reading)

        var live = LiveState()
        live.bottleLevel = 0.3
        #expect(try decode(LiveState.self, #"{"bottleLevel":0.3}"#) == live)
    }

    @Test func unknownKeysAreIgnored() throws {
        #expect(try decode(Prefs.self, #"{"future":1,"general":{"theme":"night"},"water":{"sips":2}}"#) == Prefs())
        #expect(try decode(LiveState.self, #"{"mood":"happy"}"#) == LiveState())
    }

    @Test func historyEventWithoutAmountDecodesToZero() throws {
        let json = #"{"date":"2026-01-02T10:00:00Z","habit":"reading","kind":"snooze"}"#
        let event = try decode(HistoryEvent.self, json)
        #expect(event.habit == .reading)
        #expect(event.kind == .snooze)
        #expect(event.amount == 0)
        #expect(event.date == Date(timeIntervalSince1970: 1_767_348_000))
    }
}
