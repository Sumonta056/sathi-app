import EventKit
@testable import SathiUI
import Testing

@MainActor
@Suite("EventKit locked events")
struct EventKitLockTests {
    @Test func plainEventIsNotLocked() {
        let event = EKEvent(eventStore: EKEventStore())
        #expect(!EventKitCalendarReaderMapping.isLocked(event))
    }

    @Test func repeatingEventIsLocked() {
        let event = EKEvent(eventStore: EKEventStore())
        event.addRecurrenceRule(EKRecurrenceRule(recurrenceWith: .daily, interval: 1, end: nil))
        #expect(EventKitCalendarReaderMapping.isLocked(event))
    }
}
