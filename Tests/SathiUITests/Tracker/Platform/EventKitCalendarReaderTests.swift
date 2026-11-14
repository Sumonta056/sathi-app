import Foundation
@testable import SathiUI
import Testing

@Suite("EventKit calendar reader")
struct EventKitCalendarReaderTests {
    private let start = Date(timeIntervalSince1970: 1_000_000)

    @Test("no calendars ticked means nothing is read")
    func noCalendars() {
        #expect(!EventKitCalendarReaderMapping.isReadable(from: start, to: start.addingTimeInterval(60), calendarIDs: []))
    }

    @Test("an empty or reversed range is not read")
    func badRange() {
        #expect(!EventKitCalendarReaderMapping.isReadable(from: start, to: start, calendarIDs: ["a"]))
        #expect(!EventKitCalendarReaderMapping.isReadable(from: start, to: start.addingTimeInterval(-1), calendarIDs: ["a"]))
    }

    @Test("a ticked calendar and a real range are read")
    func readable() {
        #expect(EventKitCalendarReaderMapping.isReadable(from: start, to: start.addingTimeInterval(60), calendarIDs: ["a"]))
    }

    @MainActor
    @Test("an empty event id is never deleted and an empty id list reads nothing")
    func emptyInputs() {
        let writer = EventKitCalendarWriter()
        #expect(writer.delete(eventID: "") == .failed)
        #expect(writer.events(from: start, to: start.addingTimeInterval(60), calendarIDs: []).isEmpty)
    }
}
