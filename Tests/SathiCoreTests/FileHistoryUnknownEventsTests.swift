import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@Suite("FileHistoryStore unknown events")
struct FileHistoryUnknownEventsTests {
    private let base = makeTempFolder()
    private let zone = FixedZone.berlin
    private let water = #"{"date":"2026-10-05T08:00:00Z","habit":"water","kind":"done","amount":1}"#
    private let reading = #"{"date":"2026-10-06T19:00:00Z","habit":"reading","kind":"done","amount":15}"#
    private static let stretch = #"{"date":"2026-10-07T08:00:00Z","habit":"stretch","kind":"done","amount":3,"x":{"r":[1,2.5,null,true],"n":"a"}}"#
    private static let newKind = #"{"date":"2026-10-08T08:00:00Z","habit":"water","kind":"refill","amount":2}"#
    private static let noDate = #"{"habit":"reading","kind":"done","amount":10}"#

    private var folder: URL { base.appendingPathComponent("history") }
    private var october: URL { folder.appendingPathComponent("2026-10.json") }
    private var corrupt: URL { folder.appendingPathComponent("2026-10.json.corrupt") }

    private func store() -> FileHistoryStore { FileHistoryStore(base: base, calendar: zone.calendar, delay: 3600) }

    private func at(_ iso: String) -> Date { ISO8601DateFormatter().date(from: iso)! }

    private var knownEvents: [HistoryEvent] {
        [.done(.water, 1, at: at("2026-10-05T08:00:00Z")), .done(.reading, 15, at: at("2026-10-06T19:00:00Z"))]
    }

    private func writeOctober(_ elements: [String]) throws {
        try writeText(#"{"schemaVersion":1,"value":["# + elements.joined(separator: ",") + "]}", to: october)
    }

    private func raw(_ text: String) throws -> RawJSON {
        try JSONDecoder().decode(RawJSON.self, from: Data(text.utf8))
    }

    private func fileValue() throws -> [RawJSON] {
        let data = try #require(readData(october))
        let file = try JSONDecoder().decode([String: RawJSON].self, from: data)
        guard case let .array(value) = try #require(file["value"]) else { throw CocoaError(.coderReadCorrupt) }
        return value
    }

    @Test func eventsReturnsOnlyTheKnownEventsOfTheMonth() throws {
        try writeOctober([water, reading, Self.stretch])
        let s = store()
        #expect(s.events(from: zone.date(2026, 10, 1), to: zone.date(2026, 11, 1)) == knownEvents)
        #expect(!fileExists(corrupt))
        #expect(fileExists(october))
    }

    @Test func allEventsReturnsOnlyTheKnownEventsOfTheMonth() throws {
        try writeOctober([water, reading, Self.stretch])
        #expect(store().allEvents() == knownEvents)
        #expect(!fileExists(corrupt))
    }

    @Test(arguments: [newKind, noDate])
    func anEventThatDoesNotDecodeIsKeptAsUnknown(_ unknown: String) throws {
        try writeOctober([water, reading, unknown])
        let s = store()
        #expect(s.events(from: zone.date(2026, 10, 1), to: zone.date(2026, 11, 1)) == knownEvents)
        #expect(!fileExists(corrupt))
        s.append(.snooze(.water, at: zone.date(2026, 10, 20, 10)))
        #expect(s.flush())
        let value = try fileValue()
        #expect(value.count == 4)
        #expect(try value.contains(raw(unknown)))
    }

    @Test func appendWritesTheOldEventsTheNewEventAndTheUnknownEventUnchanged() throws {
        try writeOctober([water, reading, Self.stretch])
        let s = store()
        _ = s.events(from: zone.date(2026, 10, 1), to: zone.date(2026, 11, 1))
        s.append(.done(.water, 2, at: at("2026-10-20T08:00:00Z")))
        #expect(s.flush())
        let added = #"{"date":"2026-10-20T08:00:00Z","habit":"water","kind":"done","amount":2}"#
        let expected = try [water, reading, added, Self.stretch].map(raw)
        #expect(try fileValue() == expected)
    }

    @Test func theUnknownEventSurvivesACacheReleaseOfItsMonth() throws {
        try writeOctober([water, reading, Self.stretch])
        let s = store()
        s.append(.done(.water, 1, at: zone.date(2026, 10, 10, 10)))
        s.append(.done(.water, 1, at: zone.date(2026, 11, 3, 10)))
        #expect(s.flush())
        s.append(.done(.water, 1, at: zone.date(2026, 10, 12, 10)))
        #expect(s.flush())
        let value = try fileValue()
        #expect(value.count == 5)
        #expect(try value.last == raw(Self.stretch))
        #expect(store().events(from: zone.date(2026, 10, 1), to: zone.date(2026, 11, 1)).count == 4)
    }

    @Test func aMonthFileWhoseValueIsNotAnArrayMovesToCorrupt() throws {
        let text = #"{"schemaVersion":1,"value":{"habit":"water"}}"#
        try writeText(text, to: october)
        #expect(store().events(from: zone.date(2026, 10, 1), to: zone.date(2026, 11, 1)).isEmpty)
        #expect(readText(corrupt) == text)
    }
}
