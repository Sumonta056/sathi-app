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
        #expect(h.presenter.calls.last == .showMain(.reports))
    }

    @Test func openMainShowsThePageAsGiven() {
        let h = EngineHarness()
        h.engine.openMain(.today)
        #expect(h.presenter.calls.last == .showMain(.today))
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
