import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("ReportScreen headline and subline")
struct ReportScreenTextTests {
    private static let starts: [(ReportRange, Int, String)] = [
        (.day, 21, "Today"), (.week, 19, "This week"), (.month, 1, "This month")
    ]

    private func fixture(_ range: ReportRange, water: Double?, enabled: Set<HabitID>) -> ReportScreenFixture {
        let start = Self.starts.first { $0.0 == range }?.1 ?? 1
        var f = ReportScreenFixture.at(2026, 10, start, 15)
        if let water { f.events = [.done(.water, water, at: ReportScreenFixture.on(2026, 10, start))] }
        f.enabled = enabled
        return f
    }

    @Test(arguments: [
        (ReportRange.day, "Today"), (.week, "This week"), (.month, "This month")
    ])
    func goalMetIsGreat(_ range: ReportRange, _ word: String) {
        #expect(fixture(range, water: 8, enabled: [.water]).screen(range).headline == "\(word), you did great")
    }

    @Test(arguments: [
        (ReportRange.day, "Today"), (.week, "This week"), (.month, "This month")
    ])
    func halfTheGoalIsNiceProgress(_ range: ReportRange, _ word: String) {
        #expect(fixture(range, water: 4, enabled: [.water]).screen(range).headline == "\(word), nice progress")
    }

    @Test(arguments: [
        (ReportRange.day, "Today"), (.week, "This week"), (.month, "This month")
    ])
    func underHalfIsEveryBitCounts(_ range: ReportRange, _ word: String) {
        #expect(fixture(range, water: 3, enabled: [.water]).screen(range).headline == "\(word), every bit counts")
        #expect(fixture(range, water: nil, enabled: [.water]).screen(range).headline == "\(word), every bit counts")
    }

    @Test(arguments: [
        (ReportRange.day, "Today"), (.week, "This week"), (.month, "This month")
    ])
    func noEnabledHabitMeansTheBuddiesRest(_ range: ReportRange, _ word: String) {
        #expect(fixture(range, water: 8, enabled: []).screen(range).headline == "\(word), your buddies are resting")
    }

    @Test func theHeadlineAveragesOnlyEnabledHabits() {
        #expect(fixture(.day, water: 8, enabled: [.water, .reading]).screen(.day).headline == "Today, nice progress")
        #expect(fixture(.day, water: 8, enabled: [.water]).screen(.day).headline == "Today, you did great")
    }

    @Test func daySublineIsWeekdayDayAndMonth() {
        #expect(ReportScreenFixture.at(2026, 10, 24).screen(.day).subline == "Saturday, 24 October")
    }

    @Test func weekInOneMonthNamesTheMonthOnce() {
        #expect(ReportScreenFixture.at(2026, 10, 21).screen(.week).subline == "19 \u{2013} 25 October")
    }

    @Test func weekAcrossTwoMonthsNamesBothMonths() {
        #expect(ReportScreenFixture.at(2026, 10, 1).screen(.week).subline == "28 September \u{2013} 4 October")
    }

    @Test func monthSublineIsMonthAndYear() {
        #expect(ReportScreenFixture.at(2026, 10, 21).screen(.month).subline == "October 2026")
    }

    @Test func rangeIsCarriedIntoTheScreen() {
        let f = ReportScreenFixture.at(2026, 10, 21)
        #expect(ReportRange.allCases.map { f.screen($0).range } == ReportRange.allCases)
    }
}
