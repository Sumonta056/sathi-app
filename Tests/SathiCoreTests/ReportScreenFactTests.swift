import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("ReportScreen facts")
struct ReportScreenFactTests {
    private var fixture: ReportScreenFixture {
        var f = ReportScreenFixture.at(2026, 10, 21, 15)
        f.events = [
            .done(.water, 6, at: ReportScreenFixture.on(2026, 10, 6)),
            .done(.water, 3, at: ReportScreenFixture.on(2026, 10, 19)),
            .done(.water, 5, at: ReportScreenFixture.on(2026, 10, 20)),
            .snooze(.water, at: ReportScreenFixture.on(2026, 10, 5)),
            .snooze(.water, at: ReportScreenFixture.on(2026, 10, 19)),
            .snooze(.water, at: ReportScreenFixture.on(2026, 10, 21)),
            .snooze(.reading, at: ReportScreenFixture.on(2026, 10, 21, 22))
        ]
        f.longest = 19
        return f
    }

    private func value(_ label: String, _ screen: ReportScreen) -> String? {
        screen.facts.first { $0.label == label }?.value
    }

    @Test func dayHasNoBestDay() {
        let facts = fixture.screen(.day).facts
        #expect(facts.map(\.label) == ["Snoozes today", "Longest streak"])
        #expect(facts.map(\.value) == ["1", "19 days"])
    }

    @Test func weekNamesTheWeekdayOfTheBestDay() {
        let facts = fixture.screen(.week).facts
        #expect(facts.map(\.label) == ["Best day", "Snoozes this week", "Longest streak"])
        #expect(facts.map(\.value) == ["Tuesday", "2", "19 days"])
        #expect(facts.map(\.id) == facts.map(\.label))
    }

    @Test func monthNamesTheDateOfTheBestDay() {
        let facts = fixture.screen(.month).facts
        #expect(facts.map(\.label) == ["Best day", "Snoozes this month", "Longest streak"])
        #expect(facts.map(\.value) == ["6 October", "3", "19 days"])
    }

    @Test(arguments: [ReportRange.week, .month])
    func noBestDayShowsADash(_ range: ReportRange) {
        #expect(value("Best day", fixture.screen(range, selected: .reading)) == "\u{2014}")
    }

    @Test func factsFollowTheSelectedHabit() {
        let screen = fixture.screen(.week, selected: .reading)
        #expect(value("Snoozes this week", screen) == "1")
    }

    @Test(arguments: [(1, "1 day"), (0, "0 days"), (19, "19 days")])
    func longestStreakIsSingularOnlyForOne(_ longest: Int, _ text: String) {
        var f = fixture
        f.longest = longest
        #expect(value("Longest streak", f.screen(.week)) == text)
    }
}
