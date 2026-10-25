import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("ReportScreen streak calendar")
struct ReportScreenCalendarTests {
    private var fixture: ReportScreenFixture {
        var f = ReportScreenFixture.at(2026, 10, 21)
        f.events = [
            .done(.water, 3.99, at: ReportScreenFixture.on(2026, 10, 2)),
            .done(.water, 4, at: ReportScreenFixture.on(2026, 10, 3)),
            .done(.water, 7.99, at: ReportScreenFixture.on(2026, 10, 4)),
            .done(.water, 8, at: ReportScreenFixture.on(2026, 10, 5)),
            .done(.water, 10, at: ReportScreenFixture.on(2026, 10, 6)),
            .done(.water, 8, at: ReportScreenFixture.on(2026, 10, 25)),
            .done(.reading, 15, at: ReportScreenFixture.on(2026, 10, 1, 21))
        ]
        return f
    }

    private func cell(_ day: Int, in month: StreakMonth) throws -> StreakCell {
        try #require(month.cells.first { $0.day == day })
    }

    @Test func titleNamesTheMonthOfNow() {
        #expect(fixture.screen(.week).calendar.title == "October streak")
    }

    @Test func theCalendarShowsTheCurrentMonthForEveryRange() {
        let f = fixture
        #expect(f.screen(.day).calendar.cells.count == 31)
        #expect(f.screen(.day).calendar == f.screen(.month).calendar)
        #expect(f.screen(.week).calendar == f.screen(.month).calendar)
    }

    @Test(arguments: [(0, "0 days"), (1, "1 day"), (2, "2 days"), (12, "12 days")])
    func streakTextIsSingularOnlyForOne(_ streak: Int, _ text: String) {
        var f = fixture
        f.streak = streak
        #expect(f.screen(.week).calendar.streakText == text)
    }

    @Test(arguments: [(2026, 10, 3), (2026, 6, 0), (2026, 11, 6), (2026, 3, 6)])
    func leadingBlanksCountFromMonday(_ year: Int, _ month: Int, _ blanks: Int) {
        #expect(ReportScreenFixture.at(year, month, 15).screen(.week).calendar.leadingBlanks == blanks)
    }

    @Test(arguments: [(2026, 10, 31), (2026, 6, 30), (2026, 2, 28), (2028, 2, 29)])
    func oneCellPerDayOfTheMonth(_ year: Int, _ month: Int, _ count: Int) {
        let cells = ReportScreenFixture.at(year, month, 15).screen(.week).calendar.cells
        #expect(cells.map(\.day) == Array(1 ... count))
        #expect(cells.map(\.id) == Array(1 ... count))
    }

    @Test(arguments: [(1, 0), (2, 1), (3, 2), (4, 2), (5, 3), (6, 3)])
    func levelComesFromTheTotalOverTheGoal(_ day: Int, _ level: Int) throws {
        #expect(try cell(day, in: fixture.screen(.week).calendar).level == level)
    }

    @Test func onlyTodayIsToday() {
        let cells = fixture.screen(.week).calendar.cells
        #expect(cells.filter(\.isToday).map(\.day) == [21])
    }

    @Test func daysAfterTodayAreFutureWithLevelZero() throws {
        let month = fixture.screen(.week).calendar
        #expect(month.cells.filter(\.isFuture).map(\.day) == Array(22 ... 31))
        #expect(try cell(25, in: month).level == 0)
        #expect(try !cell(21, in: month).isFuture)
    }

    @Test func theCalendarFollowsTheSelectedHabit() throws {
        let month = fixture.screen(.week, selected: .reading).calendar
        #expect(try cell(1, in: month).level == 3)
        #expect(try cell(5, in: month).level == 0)
    }

    @Test func aZeroGoalShadesNothing() {
        var f = fixture
        f.enabled = [.meditation]
        f.prefs.meditation.dailyGoalMinutes = 0
        f.events = [.done(.meditation, 5, at: ReportScreenFixture.on(2026, 10, 2))]
        let cells = f.screen(.week, selected: .meditation).calendar.cells
        #expect(cells.count == 31)
        #expect(cells.allSatisfy { $0.level == 0 })
    }
}
