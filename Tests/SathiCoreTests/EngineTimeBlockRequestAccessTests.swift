import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine time block request access while waiting")
struct EngineTimeBlockRequestAccessTests {
    private func waiting(_ access: CalendarAccess, choices: [CalendarChoice]? = nil) -> EngineHarness {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        h.advance(minutes: 5)
        h.calendarWriter.access = access
        if let choices { h.calendarWriter.choices = choices }
        h.engine.refreshCalendarAccess()
        h.calendarWriter.nextSaveResult = .failed
        h.engine.endBlock()
        return h
    }

    private func goneShows(_ h: EngineHarness) -> Int {
        h.presenter.calls.filter { $0 == .showBlockCalendarGone }.count
    }

    @Test func grantedFromNotAskedShowsThePopupAgainToChoose() async {
        let h = waiting(.notAsked)
        #expect(h.engine.waitingSaveState == .noAccess)
        let before = goneShows(h)
        h.calendarWriter.accessAfterRequest = .allowed
        await h.engine.requestCalendarAccess()
        #expect(h.calendarWriter.requestCount == 1)
        #expect(goneShows(h) == before + 1)
        #expect(h.presenter.calls.last == .showBlockCalendarGone)
        #expect(h.engine.waitingSaveState == .choose)
    }

    @Test func grantedWithNewCalendarsShowsThePopupAgain() async {
        let h = waiting(.notAsked, choices: [])
        let before = goneShows(h)
        h.calendarWriter.accessAfterRequest = .allowed
        h.calendarWriter.choices = [CalendarChoice(id: "home", title: "Home", account: "iCloud", colorHex: 0x34A853)]
        await h.engine.requestCalendarAccess()
        #expect(goneShows(h) == before + 1)
        #expect(h.engine.waitingSaveState == .choose)
    }

    @Test func aChangedListAloneShowsThePopupAgain() async {
        let h = waiting(.allowed)
        let before = goneShows(h)
        h.calendarWriter.choices.removeAll { $0.id == "home" }
        await h.engine.requestCalendarAccess()
        #expect(goneShows(h) == before + 1)
    }

    @Test func deniedAgainWithTheSameListDoesNotShowAgain() async {
        let h = waiting(.denied)
        let before = goneShows(h)
        h.calendarWriter.accessAfterRequest = .denied
        await h.engine.requestCalendarAccess()
        #expect(h.calendarWriter.requestCount == 1)
        #expect(goneShows(h) == before)
        #expect(h.engine.waitingSaveState == .noAccess)
    }

    @Test func noBlockNeverShowsThePopup() async {
        let h = EngineHarness.quiet()
        h.calendarWriter.access = .notAsked
        h.engine.refreshCalendarAccess()
        h.calendarWriter.accessAfterRequest = .allowed
        await h.engine.requestCalendarAccess()
        #expect(goneShows(h) == 0)
    }

    @Test func aRunningBlockNeverShowsThePopup() async {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        h.advance(minutes: 1)
        h.calendarWriter.access = .denied
        h.engine.refreshCalendarAccess()
        h.calendarWriter.accessAfterRequest = .allowed
        h.calendarWriter.choices = []
        await h.engine.requestCalendarAccess()
        #expect(goneShows(h) == 0)
    }
}
