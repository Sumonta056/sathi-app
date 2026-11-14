import EventKit
import Foundation
import SathiCore
@testable import SathiUI
import Testing

@MainActor
@Suite("EventKitCalendarChangeSource")
struct EventKitCalendarChangeSourceTests {
    private final class Box { var changes = 0 }

    @Test func storeChangeCallsTheHandler() {
        let center = NotificationCenter()
        let source = EventKitCalendarChangeSource(center: center)
        let box = Box()
        source.start { box.changes += 1 }
        center.post(name: .EKEventStoreChanged, object: nil)
        #expect(box.changes == 1)
    }

    @Test func stopRemovesTheObserver() {
        let center = NotificationCenter()
        let source = EventKitCalendarChangeSource(center: center)
        let box = Box()
        source.start { box.changes += 1 }
        source.stop()
        center.post(name: .EKEventStoreChanged, object: nil)
        #expect(box.changes == 0)
    }

    @Test func aSecondStartReplacesTheFirst() {
        let center = NotificationCenter()
        let source = EventKitCalendarChangeSource(center: center)
        let first = Box()
        let second = Box()
        source.start { first.changes += 1 }
        source.start { second.changes += 1 }
        center.post(name: .EKEventStoreChanged, object: nil)
        #expect(first.changes == 0)
        #expect(second.changes == 1)
    }
}
