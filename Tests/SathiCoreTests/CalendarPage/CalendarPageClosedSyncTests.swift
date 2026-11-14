import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Calendar page closed and tracker")
struct CalendarPageClosedSyncTests {
    private func readingTracker(_ mode: EventMode = .logAndTell) -> EngineHarness {
        let h = EngineHarness.syncedPage(mode, opened: false)
        h.engine.start()
        return h
    }

    @Test(arguments: [EventMode.askFirst, .logAndTell])
    func outsideEventWhilePageClosedReactsAtItsStart(_ mode: EventMode) {
        let h = readingTracker(mode)
        h.at(wed(11))
        h.calendarWriter.eventsValue.append(meeting("x1", from: wed(14), to: wed(14, 30)))
        h.calendarChanges.fire()
        #expect(h.calendarChanges.isListening)
        for minute in 1 ... 180 {
            h.at(wed(11).addingTimeInterval(TimeInterval(minute) * 60))
        }
        #expect(h.reacted(to: "x1", mode))
    }

    @Test func closedPageChangeDoesNoPageWork() {
        let h = readingTracker()
        let revision = h.engine.storeRevision
        let calls = h.calendarWriter.calendarsCalls
        h.calendarChanges.fire()
        #expect(h.engine.storeRevision == revision)
        #expect(h.calendarWriter.calendarsCalls == calls)
    }

    @Test func trackerOffDoesNotListen() {
        let h = EngineHarness(at: wed(10))
        h.engine.start()
        #expect(!h.calendarChanges.isListening)
        #expect(h.calendarChanges.starts == 0)
    }

    @Test func trackerWithNoTickedCalendarDoesNotListen() {
        let h = EngineHarness.tracker(at: wed(10))
        h.engine.start()
        h.useEvents([], read: [])
        #expect(!h.calendarChanges.isListening)
        #expect(h.calendarChanges.starts == 0)
    }

    @Test func tickedListTurnsListeningOnAndOff() {
        let h = EngineHarness.tracker(at: wed(10))
        h.engine.start()
        h.useEvents([], read: ["work"])
        #expect(h.calendarChanges.isListening)
        h.useEvents([], read: [])
        #expect(!h.calendarChanges.isListening)
        #expect(h.calendarChanges.starts == 1)
        #expect(h.calendarChanges.stops == 1)
    }

    @Test func pageAndTrackerShareOneListener() {
        let h = readingTracker()
        #expect(h.calendarChanges.starts == 1)
        h.engine.calendarPageOpened()
        #expect(h.calendarChanges.starts == 1)
        h.engine.calendarPageClosed()
        #expect(h.calendarChanges.isListening)
        #expect(h.calendarChanges.stops == 0)
    }

    @Test func trackerOffWhilePageOpenKeepsListeningUntilClose() {
        let h = readingTracker()
        h.engine.calendarPageOpened()
        h.engine.data.prefs.tracker.isOn = false
        #expect(h.calendarChanges.isListening)
        #expect(h.calendarChanges.stops == 0)
        h.engine.calendarPageClosed()
        #expect(!h.calendarChanges.isListening)
        #expect(h.calendarChanges.starts == 1)
        #expect(h.calendarChanges.stops == 1)
    }

    @Test func engineStopStopsTheTrackerListener() {
        let h = readingTracker()
        h.engine.stop()
        #expect(!h.calendarChanges.isListening)
        #expect(h.calendarChanges.stops == 1)
    }
}
