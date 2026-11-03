import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine time block access refresh from the menu")
struct EngineTimeBlockMenuRefreshTests {
    private func waiting(_ access: CalendarAccess = .allowed, choices: [CalendarChoice]? = nil) -> EngineHarness {
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

    private let home = CalendarChoice(id: "home", title: "Home", account: "iCloud", colorHex: 0x34A853)

    @Test func accessBackShowsThePopupAgainToChoose() {
        let h = waiting(.denied, choices: [])
        let before = goneShows(h)
        h.calendarWriter.access = .allowed
        h.calendarWriter.choices = [home]
        h.engine.refreshCalendarAccess()
        #expect(goneShows(h) == before + 1)
        #expect(h.presenter.calls.last == .showBlockCalendarGone)
        #expect(h.engine.waitingSaveState == .choose)
    }

    @Test func aChangedListShowsThePopupAgain() {
        let h = waiting()
        let before = goneShows(h)
        h.calendarWriter.choices.removeAll { $0.id == "home" }
        h.engine.refreshCalendarAccess()
        #expect(goneShows(h) == before + 1)
    }

    @Test func nothingChangedDoesNotShowThePopupAgain() {
        let h = waiting()
        let before = goneShows(h)
        h.engine.refreshCalendarAccess()
        h.engine.refreshCalendarAccess()
        #expect(goneShows(h) == before)
    }

    @Test func noWaitingBlockNeverShowsThePopup() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        h.calendarWriter.access = .denied
        h.engine.refreshCalendarAccess()
        h.calendarWriter.access = .allowed
        h.calendarWriter.choices = [home]
        h.engine.refreshCalendarAccess()
        #expect(goneShows(h) == 0)
    }

    @Test func theNextMinuteCheckDoesNotShowTheSameChangeAgain() {
        let h = waiting(.denied, choices: [])
        let before = goneShows(h)
        h.calendarWriter.access = .allowed
        h.calendarWriter.choices = [home]
        h.engine.refreshCalendarAccess()
        h.advance(minutes: 1)
        h.advance(minutes: 1)
        #expect(goneShows(h) == before + 1)
    }
}

@MainActor
@Suite("Engine time block waiting with stale access")
struct EngineTimeBlockStaleAccessTests {
    @Test func endNowAfterLostAccessWaitsWithNoAccess() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        h.advance(minutes: 5)
        h.calendarWriter.access = .denied
        h.calendarWriter.choices = []
        h.calendarWriter.nextSaveResult = .calendarMissing
        h.engine.endBlock()
        #expect(h.engine.timeBlock?.waitingForCalendar == true)
        #expect(h.engine.calendarAccess == .denied)
        #expect(h.engine.waitingSaveState == .noAccess)
    }

    @Test func plannedEndAfterLostAccessWaitsWithNoAccess() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        h.advance(minutes: 29.5)
        h.calendarWriter.access = .denied
        h.calendarWriter.choices = []
        h.calendarWriter.nextSaveResult = .calendarMissing
        h.advance(minutes: 0.5)
        #expect(h.engine.timeBlock?.waitingForCalendar == true)
        #expect(h.engine.calendarAccess == .denied)
        #expect(h.engine.waitingSaveState == .noAccess)
    }

    @Test func aFailedSaveHereAfterLostAccessShowsNoAccess() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        h.advance(minutes: 5)
        h.calendarWriter.nextSaveResult = .failed
        h.engine.endBlock()
        #expect(h.engine.waitingSaveState == .choose)
        h.calendarWriter.access = .denied
        h.engine.saveWaitingBlock(to: "work")
        #expect(h.engine.timeBlock?.waitingForCalendar == true)
        #expect(h.engine.calendarAccess == .denied)
        #expect(h.engine.waitingSaveState == .noAccess)
    }
}
