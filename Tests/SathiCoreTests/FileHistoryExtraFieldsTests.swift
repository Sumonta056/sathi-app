import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@Suite("FileHistoryStore extra fields")
struct FileHistoryExtraFieldsTests {
    private let base = makeTempFolder()
    private let zone = FixedZone.berlin
    private let withExtras = #"{"date":"2026-10-05T08:00:00Z","habit":"water","kind":"done","amount":1,"#
        + #""note":"gym","meta":{"tags":["a",2],"ok":false},"flag":true,"count":7}"#
    private let noAmount = #"{"date":"2026-10-06T19:00:00Z","habit":"reading","kind":"skip","note":"late","flag":true}"#
    private let stretch = #"{"date":"2026-10-07T08:00:00Z","habit":"stretch","kind":"done","amount":3}"#

    private var october: URL { base.appendingPathComponent("history").appendingPathComponent("2026-10.json") }

    private func store() -> FileHistoryStore { FileHistoryStore(base: base, calendar: zone.calendar, delay: 3600) }

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

    private func object(_ value: RawJSON) throws -> [String: RawJSON] {
        guard case let .object(fields) = value else { throw CocoaError(.coderReadCorrupt) }
        return fields
    }

    private func appendAndFlush() {
        let s = store()
        s.append(.done(.water, 2, at: zone.date(2026, 10, 20, 10)))
        #expect(s.flush())
    }

    @Test func aKnownEventKeepsEveryExtraKeyAfterAWrite() throws {
        try writeOctober([withExtras])
        appendAndFlush()
        let value = try fileValue()
        #expect(value.count == 2)
        #expect(try value.first == raw(withExtras))
    }

    @Test func extraKeysStayNextToTheKnownFieldsOfEachEvent() throws {
        try writeOctober([withExtras, noAmount])
        appendAndFlush()
        let value = try fileValue()
        #expect(value.count == 3)
        let second = try object(value[1])
        #expect(second["note"] == .string("late"))
        #expect(second["flag"] == .bool(true))
        #expect(second["habit"] == .string("reading"))
        let added = try object(value[2])
        #expect(added["note"] == nil)
        #expect(added.keys.sorted() == ["amount", "date", "habit", "kind"])
    }

    @Test func theKnownFieldsAreWrittenFromTheHistoryEventValues() throws {
        try writeOctober([noAmount])
        appendAndFlush()
        let first = try object(fileValue()[0])
        #expect(first["date"] == .string("2026-10-06T19:00:00Z"))
        #expect(first["habit"] == .string("reading"))
        #expect(first["kind"] == .string("skip"))
        #expect(first["amount"] == .number(0))
    }

    @Test func anUnknownEventOfAFileThatLaterBreaksIsNotWrittenBack() throws {
        try writeOctober([withExtras, stretch])
        let s = store()
        #expect(s.events(from: zone.date(2026, 10, 1), to: zone.date(2026, 11, 1)).count == 1)
        try writeText("garbage", to: october)
        s.append(.done(.water, 2, at: zone.date(2026, 10, 20, 10)))
        #expect(s.flush())
        let value = try fileValue()
        #expect(try !value.contains(raw(stretch)))
        #expect(value.count == 1)
    }
}
