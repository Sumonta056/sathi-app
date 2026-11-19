import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine main page")
struct EngineMainPageTests {
    @Test func openSettingsShowsTheGeneralPage() {
        let h = EngineHarness()
        h.engine.openSettings()
        #expect(h.presenter.calls.last == .showMain(.settings(.general)))
    }

    @Test func openSettingsOnAPageShowsThatPage() {
        let h = EngineHarness()
        h.engine.openSettings(.tracker)
        #expect(h.presenter.calls.last == .showMain(.settings(.tracker)))
    }

    @Test func openReportsShowsTheReportsPage() {
        let h = EngineHarness()
        h.engine.openReports()
        #expect(h.presenter.calls.last == .showMain(.dashboard(.week)))
    }

    @Test func openMainShowsThePageAsGiven() {
        let h = EngineHarness()
        h.engine.openMain(.dashboard(.day))
        #expect(h.presenter.calls.last == .showMain(.dashboard(.day)))
    }

    @Test func openMainShowsTheCalendarPage() {
        let h = EngineHarness()
        h.engine.openMain(.calendar(nil))
        #expect(h.presenter.calls.last == .showMain(.calendar(nil)))
    }

    @Test func openMainTodosFallsBackToTodayWhenTodosIsOff() {
        let h = EngineHarness()
        h.engine.openMain(.todos)
        #expect(h.presenter.calls.last == .showMain(.dashboard(.day)))
    }

    @Test func openMainTodosShowsTheTodosPageWhenOn() {
        let h = EngineHarness { $0.prefs.todos.isOn = true }
        h.engine.openMain(.todos)
        #expect(h.presenter.calls.last == .showMain(.todos))
    }

    @Test func openActivityReportShowsThatDayAndClosesTheEndOfDayPopup() {
        let h = EngineHarness.tracker(at: wed(17, 50))
        h.engine.skipTrackerPrompt()
        h.advance(minutes: 10)
        let day = DayKey(wed(18), calendar: .current)
        h.engine.openActivityReport(day)
        #expect(h.presenter.calls.last == .showMain(.activities(day)))
        #expect(h.presenter.trackerCalls.last == .closeEndOfDay)
    }
}
