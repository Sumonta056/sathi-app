import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Calendar page and tracker agree after logging")
struct CalendarPageTrackerLogTests {
    @Test(arguments: [EventMode.askFirst, .logAndTell])
    func untickedCalendarShowsButNoReaction(_ mode: EventMode) {
        let h = EngineHarness.syncedPage(mode)
        let id = h.createOnPage("Dentist", calendarID: "home")
        h.at(wed(11))
        #expect(h.pageShowsEvent(id))
        h.at(wed(14))
        #expect(!h.reactedToAny)
        #expect(h.pageShowsEvent(id))
    }

    @Test(arguments: [EventMode.askFirst, .logAndTell])
    func afterLoggingPageShowsOneActivityAndKeepsThePlan(_ mode: EventMode) {
        let h = EngineHarness.syncedPage(mode)
        let id = h.createOnPage()
        h.at(wed(14))
        if mode == .askFirst { h.engine.answerEventAsk(true) }
        #expect(h.running?.sourceEventID == id)
        h.at(wed(14, 10))
        expectOneActivityBlock(h)
        #expect(h.pageShowsEvent(id))
        h.clock.now = wed(14, 30)
        h.engine.startActivity(h.work("Review"), switchAt: wed(14, 30))
        #expect(h.saved.contains { $0.sourceEventID == id && $0.text == "Design" })
        expectOneActivityBlock(h)
        #expect(h.pageShowsEvent(id))
    }

    @Test(arguments: [EventMode.askFirst, .logAndTell])
    func pageWriteWhilePageClosedReactsAtItsStart(_ mode: EventMode) {
        let h = EngineHarness.syncedPage(mode, opened: false)
        h.at(wed(11))
        let id = h.createOnPage()
        h.at(wed(14))
        #expect(h.reacted(to: id, mode))
    }

    private func expectOneActivityBlock(_ h: EngineHarness, sourceLocation: SourceLocation = #_sourceLocation) {
        let design = h.blocks(titled: "Design").filter { if case .event = $0.source { false } else { true } }
        #expect(design.count == 1, sourceLocation: sourceLocation)
        guard case .activity = design.first?.source else {
            Issue.record("Design block is not an activity", sourceLocation: sourceLocation)
            return
        }
    }
}
