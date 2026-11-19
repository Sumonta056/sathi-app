import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@Suite("Quick panel copy")
struct CopywriterQuickPanelTests {
    private let cal = Calendar.current
    private let due = day(2026, 3, 3, 16, 0)

    private func buddy(_ id: HabitID, _ status: TodayBuddyStatus, total: String = "0", goal: Int = 8, progress: Double = 0) -> TodayBuddy {
        TodayBuddy(
            habit: id, total: total, goal: goal,
            unit: id == .water ? Copywriter.todayGlassesUnit : Copywriter.todayMinutesUnit,
            progress: progress, status: status
        )
    }

    @Test func dashboardLinkSaysDashboard() {
        #expect(Copywriter.quickPanelDashboard == "Dashboard")
    }

    @Test func clockShowsShortWeekdayAndTime() {
        let text = Copywriter.quickPanelClock(day(2026, 3, 3, 14, 52), calendar: cal)
        #expect(text.hasPrefix("Tue"))
        #expect(text.hasSuffix("14:52"))
    }

    @Test func nowLineShowsMinutes() {
        #expect(Copywriter.quickPanelNow(42 * 60) == "NOW · 42 min")
        #expect(Copywriter.quickPanelNow(65 * 60) == "NOW · 1 h 5 min")
    }

    @Test func metOffAndDayOffHaveFixedWords() {
        #expect(Copywriter.quickPanelStatus(buddy(.reading, .met), calendar: cal) == "✓ Goal met")
        #expect(Copywriter.quickPanelStatus(buddy(.reading, .off), calendar: cal) == "Off")
        #expect(Copywriter.quickPanelStatus(buddy(.reading, .dayOff), calendar: cal) == "Day off")
    }

    @Test func dueNowPausedAndSnoozedReuseTodayWords() {
        #expect(Copywriter.quickPanelStatus(buddy(.reading, .dueNow), calendar: cal) == Copywriter.todayDueNow)
        #expect(Copywriter.quickPanelStatus(buddy(.reading, .paused), calendar: cal) == Copywriter.todayPaused)
        #expect(
            Copywriter.quickPanelStatus(buddy(.reading, .snoozed(due)), calendar: cal)
                == Copywriter.todaySnoozed(until: due, calendar: cal)
        )
    }

    @Test func waterAlwaysShowsProgress() {
        let b = buddy(.water, .next(due), total: "5", goal: 8, progress: 0.6)
        #expect(Copywriter.quickPanelStatus(b, calendar: cal) == "5 / 8")
        #expect(Copywriter.quickPanelStatus(buddy(.water, .next(due), total: "0"), calendar: cal) == "0 / 8")
    }

    @Test func minuteBuddyShowsProgressOnceStarted() {
        let b = buddy(.gym, .gymSession(1, of: 2, due), total: "10", goal: 20, progress: 0.5)
        #expect(Copywriter.quickPanelStatus(b, calendar: cal) == "10 / 20 min")
    }

    @Test func minuteBuddyShowsNextTimeBeforeStarting() {
        let b = buddy(.meditation, .next(due), goal: 10)
        #expect(Copywriter.quickPanelStatus(b, calendar: cal) == Copywriter.trackerClock(due, calendar: cal))
    }

    @Test func noReminderShowsProgress() {
        let b = buddy(.reading, .noReminder, total: "3", goal: 20, progress: 0.15)
        #expect(Copywriter.quickPanelStatus(b, calendar: cal) == "3 / 20 min")
    }
}
