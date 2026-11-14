import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Calendar page and tracker agree")
struct CalendarPageTrackerSyncTests {
    @Test(arguments: [EventMode.askFirst, .logAndTell])
    func createdOnPageReactsAtItsStart(_ mode: EventMode) {
        let h = EngineHarness.syncedPage(mode)
        let id = h.createOnPage()
        #expect(id == "e1")
        h.at(wed(13, 59))
        #expect(!h.reactedToAny)
        h.at(wed(14))
        #expect(h.reacted(to: id, mode))
    }

    @Test(arguments: [EventMode.askFirst, .logAndTell])
    func outsideEventShowsAfterChangeAndReacts(_ mode: EventMode) {
        let h = EngineHarness.syncedPage(mode)
        h.at(wed(11))
        h.calendarWriter.eventsValue.append(meeting("x1", from: wed(14), to: wed(14, 30)))
        h.calendarChanges.fire()
        #expect(h.pageShowsEvent("x1"))
        h.at(wed(13, 59))
        #expect(!h.reactedToAny)
        h.at(wed(14))
        #expect(h.reacted(to: "x1", mode))
    }

    @Test(arguments: [EventMode.askFirst, .logAndTell])
    func deletedOnPageBeforeStartGivesNoReaction(_ mode: EventMode) {
        let h = EngineHarness.syncedPage(mode)
        let id = h.createOnPage()
        h.at(wed(11))
        #expect(h.pageShowsEvent(id))
        #expect(h.engine.deleteCalendarPageEvent(id))
        #expect(!h.pageShowsEvent(id))
        h.at(wed(14))
        #expect(!h.reactedToAny)
    }

    @Test(arguments: [EventMode.askFirst, .logAndTell])
    func deletedOutsideBeforeStartGivesNoReaction(_ mode: EventMode) {
        let h = EngineHarness.syncedPage(mode)
        h.calendarWriter.eventsValue.append(meeting("x1", from: wed(14), to: wed(14, 30)))
        h.calendarChanges.fire()
        h.at(wed(11))
        h.calendarWriter.eventsValue.removeAll { $0.id == "x1" }
        h.calendarChanges.fire()
        #expect(!h.pageShowsEvent("x1"))
        h.at(wed(14))
        #expect(!h.reactedToAny)
    }

    @Test(arguments: [EventMode.askFirst, .logAndTell])
    func movedLaterOnPageReactsOnlyAtNewStart(_ mode: EventMode) {
        let h = EngineHarness.syncedPage(mode)
        let id = h.createOnPage()
        h.at(wed(11))
        guard let e = h.pageDay.blocks.compactMap({ if case let .event(e) = $0.source { e } else { nil } }).first else {
            Issue.record("no event block")
            return
        }
        var f = h.engine.calendarPageForm(for: e)
        f.start = wed(15)
        f.end = wed(15, 30)
        #expect(h.engine.saveCalendarPageEvent(f) == .saved(id))
        h.at(wed(14))
        #expect(!h.reactedToAny)
        h.at(wed(15))
        #expect(h.reacted(to: id, mode))
    }

    @Test(arguments: [EventMode.askFirst, .logAndTell])
    func movedLaterOutsideReactsOnlyAtNewStart(_ mode: EventMode) {
        let h = EngineHarness.syncedPage(mode)
        h.calendarWriter.eventsValue.append(meeting("x1", from: wed(14), to: wed(14, 30)))
        h.calendarChanges.fire()
        h.at(wed(11))
        h.calendarWriter.eventsValue = [meeting("x1", from: wed(15), to: wed(15, 30))]
        h.calendarChanges.fire()
        h.at(wed(14))
        #expect(!h.reactedToAny)
        h.at(wed(15))
        #expect(h.reacted(to: "x1", mode))
    }

    @Test(arguments: [EventMode.askFirst, .logAndTell])
    func aLaterStoreChangeGivesNoSecondReaction(_ mode: EventMode) {
        let h = EngineHarness.syncedPage(mode)
        h.calendarWriter.eventsValue.append(meeting("x1", from: wed(14), to: wed(14, 30)))
        h.calendarChanges.fire()
        h.at(wed(14))
        #expect(h.reacted(to: "x1", mode))
        let prompts = h.trackerShows.count
        let notes = h.notes.count
        let logged = h.saved.count { $0.sourceEventID == "x1" }
        h.calendarWriter.eventsValue = [meeting("x1", "Standup moved", from: wed(14), to: wed(14, 45))]
        h.calendarChanges.fire()
        h.at(wed(14, 1))
        h.calendarChanges.fire()
        h.at(wed(14, 2))
        #expect(h.trackerShows.count == prompts)
        #expect(h.notes.count == notes)
        #expect(h.saved.count { $0.sourceEventID == "x1" } == logged)
    }
}
