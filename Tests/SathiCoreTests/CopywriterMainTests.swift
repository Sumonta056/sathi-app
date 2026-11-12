import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Main window copy")
struct CopywriterMainTests {
    private let zone = FixedZone.berlin

    @Test func pagesHaveTheirSidebarNames() {
        #expect(Copywriter.mainPageToday == "Today")
        #expect(Copywriter.mainPageActivities == "Activities")
        #expect(Copywriter.mainPageReports == "Reports")
    }

    @Test func settingsPagesHaveTheirSidebarNamesInOrder() {
        let names = SettingsPage.all.map(Copywriter.settingsPageTitle)
        #expect(names == ["General", "Fota", "Boi", "Shanti", "Shokti", "Quick reminders", "Activity tracker", "Time blocks", "Sound"])
    }

    @Test func trackerStatusWords() {
        #expect(Copywriter.mainTrackerOn == "TRACKER ON")
        #expect(Copywriter.mainTrackerOff == "TRACKER OFF")
    }

    @Test func trackerHoursShowTheSpanAndTheAskInterval() {
        let start = zone.date(2026, 3, 4, 9, 0)
        let end = zone.date(2026, 3, 4, 18, 0)
        let text = Copywriter.mainTrackerHours(start, end, askEvery: 30, calendar: zone.calendar)
        #expect(text == Copywriter.trackerSpan(start, end, calendar: zone.calendar) + " · asks every 30 min")
    }
}
