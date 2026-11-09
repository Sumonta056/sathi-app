import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Activity model")
struct ActivityModelTests {
    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try decode(type, Data(json.utf8))
    }

    private func decode<T: Decodable>(_ type: T.Type, _ data: Data) throws -> T {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return try d.decode(type, from: data)
    }

    private func encode(_ value: some Encodable) throws -> Data {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return try e.encode(value)
    }

    @Test(arguments: [
        ("  Client work  ", "Client work"),
        ("Fix\nlogin\r\nbug", "Fix login bug"),
        ("\n\t Standup \n", "Standup")
    ])
    func textIsTrimmedAndLineBreaksBecomeSpaces(raw: String, clean: String) {
        #expect(ActivityText.clean(raw) == clean)
    }

    @Test(arguments: ["", "   ", "\n\n"])
    func emptyTextIsRefused(raw: String) {
        #expect(ActivityText.clean(raw) == nil)
    }

    @Test func textIsCutAtTheMaximum() {
        let long = String(repeating: "a", count: 100)
        #expect(ActivityText.clean(long)?.count == Limits.activityTextMax)
        #expect(Limits.activityTextMax == 80)
    }

    @Test func activityRoundsItsTimesToWholeSeconds() {
        let start = day(2026, 11, 9, 9).addingTimeInterval(0.6)
        let a = Activity(text: "Plan", start: start, end: start.addingTimeInterval(120))
        #expect(a.start == start.wholeSecond)
        #expect(a.end == start.addingTimeInterval(120).wholeSecond)
        #expect(a.length == 120)
    }

    @Test func activityRoundTrips() throws {
        let start = day(2026, 11, 9, 12)
        let a = Activity(
            kind: .away, text: "", start: start, end: start.addingTimeInterval(2700),
            awayPlace: .lunch, calendarID: "work", eventID: "e1", sourceEventID: "s1"
        )
        #expect(try decode(Activity.self, encode(a)) == a)
    }

    @Test func missingOptionalFieldsLoadAsEmpty() throws {
        let id = UUID().uuidString
        let a = try decode(Activity.self, #"{"id":"\#(id)","kind":"work","start":"2026-11-09T09:00:00Z","end":"2026-11-09T10:00:00Z"}"#)
        #expect(a.text == "")
        #expect(a.category == nil)
        #expect(a.awayPlace == nil)
        #expect(a.calendarID == nil)
    }

    @Test func anUnknownPlaceLoadsAsNoPlace() throws {
        let id = UUID().uuidString
        let json = #"{"id":"\#(id)","kind":"away","text":"","awayPlace":"moon","start":"2026-11-09T09:00:00Z","end":"2026-11-09T10:00:00Z"}"#
        #expect(try decode(Activity.self, json).awayPlace == nil)
    }

    @Test(arguments: [
        #"{"kind":"work","start":"2026-11-09T09:00:00Z","end":"2026-11-09T10:00:00Z"}"#,
        #"{"id":"5B1E0C9A-7B0B-4C0F-9D7A-111111111111","kind":"nap","start":"2026-11-09T09:00:00Z","end":"2026-11-09T10:00:00Z"}"#,
        #"{"id":"5B1E0C9A-7B0B-4C0F-9D7A-111111111111","kind":"work","end":"2026-11-09T10:00:00Z"}"#
    ])
    func anItemWithoutItsCoreFieldsDoesNotDecode(json: String) {
        #expect(throws: (any Error).self) { try decode(Activity.self, json) }
    }

    @Test func lengthChoicesAreTheChipsThenOpen() {
        #expect(ActivityLength.choices == [.minutes(15), .minutes(30), .minutes(60), .open])
        #expect(ActivityLength.open.minutes == nil)
        #expect(ActivityLength.minutes(30).interval == 1800)
    }

    @Test func lengthRoundTripsAndRefusesBadValues() throws {
        for length in [ActivityLength.open, .minutes(45)] {
            #expect(try decode(ActivityLength.self, encode(length)) == length)
        }
        #expect(throws: (any Error).self) { try decode(ActivityLength.self, "0") }
        #expect(throws: (any Error).self) { try decode(ActivityLength.self, #""soon""#) }
    }

    @Test func draftStartsWithTheSpecDefaults() {
        let d = ActivityDraft(text: "Plan")
        #expect(d.category == nil)
        #expect(d.length == .minutes(30))
        #expect(d.askOffsetMinutes == 0)
        #expect(d.calendarID == nil)
        #expect(!d.quiet)
        #expect(d.sourceEventID == nil)
    }

    @Test func awayPlaceChipsAreTheFiveOfPromptD() {
        #expect(AwayPlace.choices == [.lunch, .meeting, .walk, .commute, .other])
    }
}
