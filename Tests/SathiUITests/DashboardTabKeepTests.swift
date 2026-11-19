import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import Testing

@MainActor
@Suite("Dashboard tab keep")
struct DashboardTabKeepTests {
    @Test func aRangeChangeKeepsTheSelectedTab() {
        let h = ReportsFixture.harness()
        let week = ReportsFixture.week()
        let month = week.changed(to: .month, now: h.engine.now)
        let back = week.previous
        #expect(DashboardPage.shown(.gym, scores: h.engine.reportsOverview(week).scores) == .gym)
        #expect(DashboardPage.shown(.gym, scores: h.engine.reportsOverview(month).scores) == .gym)
        #expect(DashboardPage.shown(.gym, scores: h.engine.reportsOverview(back).scores) == .gym)
    }

    @Test func aBuddyThatIsOffFallsBackToAllBuddies() {
        let h = EngineHarness(at: ReportsFixture.now) { $0.prefs.gym.enabled = false }
        let week = StatsRange.containing(ReportsFixture.now, kind: .week, calendar: h.engine.rangeCalendar)
        #expect(DashboardPage.shown(.gym, scores: h.engine.reportsOverview(week).scores) == nil)
    }
}
