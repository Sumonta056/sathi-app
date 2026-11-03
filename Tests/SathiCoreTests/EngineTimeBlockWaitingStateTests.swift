import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine time block waiting save state")
struct EngineTimeBlockWaitingStateTests {
    private func waiting() -> EngineHarness {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        h.advance(minutes: 5)
        h.calendarWriter.nextSaveResult = .failed
        h.engine.endBlock()
        return h
    }

    @Test func allowedWithCalendarsLetsTheUserChoose() {
        let h = waiting()
        #expect(h.engine.timeBlock?.waitingForCalendar == true)
        #expect(h.engine.waitingSaveState == .choose)
    }

    @Test(arguments: [CalendarAccess.denied, .notAsked])
    func noAccessWins(_ access: CalendarAccess) {
        let h = waiting()
        h.calendarWriter.access = access
        h.engine.refreshCalendarAccess()
        #expect(h.engine.waitingSaveState == .noAccess)
    }

    @Test func noAccessWinsEvenWithNoCalendars() {
        let h = waiting()
        h.calendarWriter.access = .denied
        h.calendarWriter.choices = []
        h.engine.refreshCalendarAccess()
        #expect(h.engine.waitingSaveState == .noAccess)
    }

    @Test func allowedWithoutWritableCalendarsHasNoCalendar() {
        let h = waiting()
        h.calendarWriter.choices = []
        h.engine.refreshCalendarAccess()
        #expect(h.engine.waitingSaveState == .noCalendar)
    }

    @Test func aLostAccessIsSeenAtTheNextTick() {
        let h = waiting()
        h.calendarWriter.access = .denied
        h.advance(minutes: 1)
        #expect(h.engine.waitingSaveState == .noAccess)
    }
}

@MainActor
@Suite("Engine time block waiting popup refresh")
struct EngineTimeBlockWaitingRefreshTests {
    private func waiting() -> EngineHarness {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        h.advance(minutes: 5)
        h.calendarWriter.nextSaveResult = .failed
        h.engine.endBlock()
        return h
    }

    private func goneShows(_ h: EngineHarness) -> Int {
        h.presenter.calls.filter { $0 == .showBlockCalendarGone }.count
    }

    @Test func lostAccessShowsThePopupAgain() {
        let h = waiting()
        let before = goneShows(h)
        h.calendarWriter.access = .denied
        h.advance(minutes: 1)
        #expect(goneShows(h) == before + 1)
        #expect(h.presenter.calls.last == .showBlockCalendarGone)
    }

    @Test func accessBackShowsThePopupAgain() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        h.advance(minutes: 5)
        h.calendarWriter.access = .denied
        h.calendarWriter.choices = []
        h.engine.refreshCalendarAccess()
        h.calendarWriter.nextSaveResult = .failed
        h.engine.endBlock()
        let before = goneShows(h)
        h.calendarWriter.access = .allowed
        h.calendarWriter.choices = [CalendarChoice(id: "home", title: "Home", account: "iCloud", colorHex: 0x34A853)]
        h.advance(minutes: 1)
        #expect(h.engine.waitingSaveState == .choose)
        #expect(goneShows(h) == before + 1)
    }

    @Test func aChangedCalendarListShowsThePopupAgain() {
        let h = waiting()
        let before = goneShows(h)
        h.calendarWriter.choices.removeAll { $0.id == "home" }
        h.advance(minutes: 1)
        #expect(h.engine.calendarChoices().map(\.id) == ["work"])
        #expect(goneShows(h) == before + 1)
    }

    @Test func nothingChangedDoesNotShowThePopupAgain() {
        let h = waiting()
        let before = goneShows(h)
        h.advance(minutes: 1)
        h.advance(minutes: 1)
        #expect(goneShows(h) == before)
    }

    @Test func noWaitingBlockNeverShowsThePopup() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        h.advance(minutes: 1)
        h.calendarWriter.access = .denied
        h.advance(minutes: 1)
        h.calendarWriter.access = .allowed
        h.calendarWriter.choices = []
        h.advance(minutes: 1)
        #expect(goneShows(h) == 0)
    }

    @Test func noBlockAtAllNeverShowsThePopup() {
        let h = EngineHarness.quiet()
        h.calendarWriter.access = .denied
        h.advance(minutes: 1)
        #expect(goneShows(h) == 0)
    }
}
