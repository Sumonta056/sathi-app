import Foundation
import SathiCore
import Testing

@Suite("Time block state decoding")
struct TimeBlockStateDecodingTests {
    private let id = UUID().uuidString

    private func lengthJSON(_ length: TimeBlockLength) throws -> String {
        try String(bytes: JSONEncoder().encode(length), encoding: .utf8) ?? ""
    }

    private func blockJSON(started: String = "792403200.734512", length: String, extra: String = "") -> String {
        #"{"id":"\#(id)","title":"Plan","startedAt":\#(started),"length":\#(length),"calendarID":"work","waitingForCalendar":false\#(extra)}"#
    }

    private func live(_ json: String) throws -> LiveState {
        try JSONDecoder().decode(LiveState.self, from: Data(json.utf8))
    }

    @Test func oldStateWithoutKeyLoadsNil() throws {
        let s = try live(#"{"bottleLevel":0.5}"#)
        #expect(s.timeBlock == nil)
        #expect(s.bottleLevel == 0.5)
    }

    @Test func aSavedBlockLoadsWithWholeSecondDates() throws {
        let json = try blockJSON(
            length: lengthJSON(.minutes(30)),
            extra: #","plannedEnd":792405000.9,"savedEventID":"e1","nextCheckIn":792410000.5,"endedAt":792405001.2"#
        )
        let block = try #require(try live(#"{"timeBlock":\#(json)}"#).timeBlock)
        #expect(block.title == "Plan")
        #expect(block.length == .minutes(30))
        #expect(block.calendarID == "work")
        #expect(block.savedEventID == "e1")
        #expect(block.startedAt == Date(timeIntervalSinceReferenceDate: 792_403_200))
        #expect(block.plannedEnd == Date(timeIntervalSinceReferenceDate: 792_405_000))
        #expect(block.nextCheckIn == Date(timeIntervalSinceReferenceDate: 792_410_000))
        #expect(block.endedAt == Date(timeIntervalSinceReferenceDate: 792_405_001))
    }

    @Test func aCorruptBlockLoadsNilAndKeepsTheRest() throws {
        let s = try live(#"{"bottleLevel":0.4,"timeBlock":"oops"}"#)
        #expect(s.timeBlock == nil)
        #expect(s.bottleLevel == 0.4)
    }

    @Test func aBlockWithAnUnknownLengthLoadsNil() throws {
        let json = blockJSON(length: #""weird""#)
        let s = try live(#"{"bottleLevel":0.4,"timeBlock":\#(json)}"#)
        #expect(s.timeBlock == nil)
        #expect(s.bottleLevel == 0.4)
    }

    @Test func aBlockMissingItsCalendarLoadsNil() throws {
        let json = try #"{"id":"\#(id)","title":"Plan","startedAt":792403200,"length":\#(lengthJSON(.open))}"#
        #expect(try live(#"{"timeBlock":\#(json)}"#).timeBlock == nil)
    }

    @Test func anOpenBlockRoundTrips() throws {
        let json = try blockJSON(length: lengthJSON(.open), extra: #","nextCheckIn":792410400"#)
        let state = try live(#"{"timeBlock":\#(json)}"#)
        let back = try JSONDecoder().decode(LiveState.self, from: JSONEncoder().encode(state))
        #expect(back.timeBlock == state.timeBlock)
        #expect(back.timeBlock?.length == .open)
        #expect(back.timeBlock?.plannedEnd == nil)
    }
}
