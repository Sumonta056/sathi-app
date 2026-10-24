import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Reading corner copy")
struct ReadingCornerCopyTests {
    private func shortTime(_ date: Date, in zone: FixedZone) -> String {
        var style = Date.FormatStyle(date: .omitted, time: .shortened)
        style.timeZone = zone.timeZone
        return date.formatted(style)
    }

    @Test func comesBackNamesBoiAndTheWallClockTime() {
        let zone = FixedZone.berlin
        let at = zone.date(2026, 3, 4, 22, 10)
        let text = Copywriter.comesBack(.reading, at: at, calendar: zone.calendar)
        #expect(text.hasPrefix("Boi comes back at "))
        #expect(text.contains("10:10") || text.contains("22:10"))
        #expect(text == "Boi comes back at " + shortTime(at, in: zone))
    }

    @Test func comesBackUsesTheCalendarTimeZone() {
        let berlin = FixedZone.berlin
        let newYork = FixedZone.newYork
        let at = berlin.date(2026, 3, 4, 22, 10)
        let text = Copywriter.comesBack(.reading, at: at, calendar: newYork.calendar)
        #expect(text == "Boi comes back at " + shortTime(at, in: newYork))
        #expect(!text.contains("10:10") && !text.contains("22:10"))
    }

    @Test(arguments: [(HabitID.water, "Fota"), (.reading, "Boi"), (.meditation, "Shanti")])
    func comesBackNamesEachBuddy(_ id: HabitID, _ buddy: String) {
        let zone = FixedZone.berlin
        let text = Copywriter.comesBack(id, at: zone.date(2026, 3, 4, 9), calendar: zone.calendar)
        #expect(text.hasPrefix("\(buddy) comes back at "))
    }

    @Test(arguments: [(15, "15 calm minutes with your book."), (30, "30 calm minutes with your book.")])
    func readingInviteHintNamesTheSessionLength(_ minutes: Int, _ expected: String) {
        #expect(Copywriter.readingInviteHint(minutes: minutes) == expected)
    }

    @Test(arguments: [(15, "Lovely, 15 minutes read"), (1, "Lovely, 1 minute read")])
    func readingDoneTitleNamesTheMinutes(_ minutes: Int, _ expected: String) {
        #expect(Copywriter.readingDoneTitle(minutes: minutes) == expected)
    }

    @Test(arguments: [(6, "That is 6 days in a row."), (2, "That is 2 days in a row."), (1, "A good start."), (0, "A good start.")])
    func readingDoneHintCelebratesTheStreak(_ streak: Int, _ expected: String) {
        #expect(Copywriter.readingDoneHint(streak: streak) == expected)
    }
}
