import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@Suite("FileActivityStore unknown data")
struct FileActivityStoreUnknownTests {
    private let base = makeTempFolder()
    private let zone = FixedZone("UTC")
    private let idA = "11111111-1111-1111-1111-111111111111"
    private let idB = "22222222-2222-2222-2222-222222222222"

    private var november: URL { base.appendingPathComponent("activities/2026-11.json") }
    private var key: MonthKey { MonthKey(year: 2026, month: 11)! }

    private var plan: String {
        #"{"id":"\#(idA)","kind":"work","text":"Plan","category":"Coding","# +
            #""start":"2026-11-09T09:00:00Z","end":"2026-11-09T09:30:00Z","tag":{"a":[1,2.5,null,true]}}"#
    }

    private var review: String {
        #"{"id":"\#(idB)","kind":"work","text":"Review","start":"2026-11-09T10:00:00Z","end":"2026-11-09T10:30:00Z"}"#
    }

    private static let newKind = #"{"id":"33333333-3333-3333-3333-333333333333","kind":"focus","text":"X","# +
        #""start":"2026-11-09T11:00:00Z","end":"2026-11-09T11:30:00Z"}"#
    private static let noEnd = #"{"id":"44444444-4444-4444-4444-444444444444","kind":"work","text":"Y","start":"2026-11-09T12:00:00Z"}"#
    private static let junk = "42"

    private func store() -> FileActivityStore { FileActivityStore(base: base, delay: 3600) }

    private func write(_ elements: [String]) throws {
        try writeText(#"{"schemaVersion":1,"value":["# + elements.joined(separator: ",") + "]}", to: november)
    }

    private func fileValue() throws -> [RawJSON] {
        let data = try #require(readData(november))
        let file = try JSONDecoder().decode([String: RawJSON].self, from: data)
        guard case let .array(value) = try #require(file["value"]) else { throw CocoaError(.coderReadCorrupt) }
        return value
    }

    private func raw(_ text: String) throws -> RawJSON {
        try JSONDecoder().decode(RawJSON.self, from: Data(text.utf8))
    }

    @Test func unreadableItemsAreDroppedFromTheMonthAndOthersStay() throws {
        try write([plan, Self.noEnd, Self.newKind, Self.junk, review])
        #expect(store().month(key).items.map(\.text) == ["Plan", "Review"])
    }

    @Test func unreadableItemsAreWrittenBackUnchanged() throws {
        try write([plan, Self.noEnd, Self.newKind, Self.junk])
        let s = store()
        var month = s.month(key)
        month.items.append(Activity(text: "New", start: zone.date(2026, 11, 9, 13), end: zone.date(2026, 11, 9, 14)))
        s.save(month)
        s.flush()
        let value = try fileValue()
        #expect(try value.suffix(3) == [raw(Self.noEnd), raw(Self.newKind), raw(Self.junk)])
        #expect(value.count == 5)
    }

    @Test func unknownFieldsOfAKnownItemSurviveASave() throws {
        try write([plan])
        let s = store()
        var month = s.month(key)
        month.items[0].text = "Plan v2"
        s.save(month)
        s.flush()
        let first = try #require(fileValue().first)
        guard case let .object(fields) = first else { throw CocoaError(.coderReadCorrupt) }
        #expect(try fields["tag"] == raw(#"{"a":[1,2.5,null,true]}"#))
        #expect(fields["text"] == .string("Plan v2"))
    }

    @Test func extrasFollowTheirItemWhenOrderChangesOrAnItemIsDeleted() throws {
        try write([review, plan])
        let s = store()
        var month = s.month(key)
        month.items.reverse()
        s.save(month)
        s.flush()
        guard case let .object(first) = try #require(fileValue().first) else { throw CocoaError(.coderReadCorrupt) }
        #expect(first["tag"] != nil)
        month.items.removeAll { $0.text == "Plan" }
        s.save(month)
        s.flush()
        #expect(try fileValue().count == 1)
    }

    @Test func aFileThatDoesNotDecodeIsMovedAsideAndTheMonthIsEmpty() throws {
        try writeText("not json", to: november)
        #expect(store().month(key).items.isEmpty)
        #expect(fileExists(base.appendingPathComponent("activities/2026-11.json.corrupt")))
    }

    @Test func aMissingOptionalFieldLoadsNil() throws {
        try write([review])
        let a = try #require(store().month(key).items.first)
        #expect(a.category == nil && a.awayPlace == nil && a.eventID == nil)
    }

    @Test func anUnknownAwayPlaceLoadsNilAndTheItemStays() throws {
        let odd = #"{"id":"\#(idA)","kind":"away","text":"Nap","start":"2026-11-09T09:00:00Z","end":"2026-11-09T09:30:00Z","awayPlace":"moon"}"#
        try write([odd])
        let a = try #require(store().month(key).items.first)
        #expect(a.awayPlace == nil)
    }
}
