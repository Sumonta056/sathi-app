import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar page lifecycle")
struct CalendarPageLifecycleTests {
    private func page(_ h: EngineHarness) throws -> InspectableView<ViewType.VStack> {
        try hosted(CalendarPage(), h).inspect().find(ViewType.VStack.self)
    }

    private func shownRange(_ view: CalendarPage, _ h: EngineHarness) throws -> CalendarPageRange {
        try hosted(view, h).inspect().find(CalendarPageHeader.self).actualView().range
    }

    @Test func theSidebarOpensOnTheDayThatHoldsNow() throws {
        let h = EngineHarness()
        let shown = try shownRange(CalendarPage(), h)
        #expect(shown.kind == .day)
        #expect(shown.holds(h.engine.now))
        #expect(shown == CalendarPageRange.containing(h.engine.now, kind: .day, calendar: h.engine.rangeCalendar))
    }

    @Test func atHalfPastOneTheFirstDayIsThePageDayThatHoldsNow() throws {
        let h = EngineHarness(at: day(2026, 11, 19, 1, 30))
        let shown = try shownRange(CalendarPage(), h)
        #expect(shown.kind == .day)
        #expect(shown.days == [DayKey(day(2026, 11, 18), calendar: h.engine.rangeCalendar)])
    }

    @Test func theFirstOpenKeepsTheRowZoomDefaultOfOneHour() {
        #expect(CalendarPagePrefs().rowMinutes == 60)
        #expect(Limits.calendarDefaultRowMinutes == 60)
    }

    @Test func aDayArgumentStillOpensThatDay() throws {
        let h = EngineHarness()
        let key = DayKey(h.engine.now, calendar: h.engine.rangeCalendar)
        let expected = CalendarPageRange.containing(day: key, kind: .day, calendar: h.engine.rangeCalendar)
        #expect(try shownRange(CalendarPage(day: key), h) == expected)
    }

    @Test func appearStartsTheChangeSourceOnce() throws {
        let h = EngineHarness()
        let sut = try page(h)
        try sut.callOnAppear()
        #expect(h.calendarChanges.isListening)
        #expect(h.calendarChanges.starts == 1)
    }

    @Test func disappearStopsTheChangeSource() throws {
        let h = EngineHarness()
        let sut = try page(h)
        try sut.callOnAppear()
        try sut.callOnDisappear()
        #expect(!h.calendarChanges.isListening)
    }

    @Test func appearReadsTheAccessAgain() throws {
        let h = EngineHarness()
        h.calendarWriter.access = .notAsked
        h.engine.refreshCalendarAccess()
        #expect(h.engine.calendarAccess == .notAsked)
        h.calendarWriter.access = .allowed
        try page(h).callOnAppear()
        #expect(h.engine.calendarAccess == .allowed)
    }

    @Test func calendarRouteSettlesOnTodayWhenTheSwitchIsOff() {
        let route = MainRoute(.calendar(nil))
        route.settle(calendarOn: false, todosOn: false)
        #expect(route.page == .today)
    }

    @Test func calendarRouteStaysWhenTheSwitchIsOn() {
        let route = MainRoute(.calendar(nil))
        route.settle(calendarOn: true, todosOn: false)
        #expect(route.page == .calendar(nil))
    }

    @Test func otherRoutesAreNotChangedBySettling() {
        let route = MainRoute(.reports)
        route.settle(calendarOn: false, todosOn: false)
        #expect(route.page == .reports)
    }

    @Test func mainViewSettlesAtOnceWhenOff() throws {
        let route = MainRoute(.calendar(nil))
        let sut = try MainView(route: route).environmentObject(EngineHarness().engine).inspect()
        try sut.find(ViewType.HStack.self).callOnAppear()
        #expect(route.page == .today)
    }
}
