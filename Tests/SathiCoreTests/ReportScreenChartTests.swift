import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("ReportScreen chart")
struct ReportScreenChartTests {
    private var fixture: ReportScreenFixture {
        var f = ReportScreenFixture.at(2026, 10, 21, 15)
        f.events = [
            .done(.water, 8, at: ReportScreenFixture.on(2026, 10, 19)),
            .done(.water, 7.75, at: ReportScreenFixture.on(2026, 10, 20)),
            .done(.water, 2, at: ReportScreenFixture.zone.date(2026, 10, 21, 9, 30)),
            .done(.meditation, 5, at: ReportScreenFixture.on(2026, 10, 19, 8))
        ]
        f.enabled = [.water, .reading, .meditation]
        return f
    }

    @Test(arguments: [
        (ReportRange.day, HabitID.water, "Water · today"),
        (.week, .water, "Water · this week"),
        (.month, .water, "Water · this month"),
        (.week, .reading, "Reading · this week"),
        (.day, .meditation, "Meditation · today")
    ])
    func titleNamesTheHabitAndRange(_ range: ReportRange, _ habit: HabitID, _ title: String) {
        #expect(fixture.screen(range, selected: habit).chart.title == title)
    }

    @Test func dayBarsAreTwoHourBucketsLabelledByStartHour() throws {
        let bars = fixture.screen(.day).chart.bars
        try #require(bars.count == 12)
        #expect(bars.map(\.label) == ["12a", "2a", "4a", "6a", "8a", "10a", "12p", "2p", "4p", "6p", "8p", "10p"])
        #expect(bars.map(\.id) == Array(0 ..< 12))
        #expect(bars[0].label == "12a")
        #expect(bars[1].label == "2a")
        #expect(bars[6].label == "12p")
        #expect(bars[11].label == "10p")
    }

    @Test(arguments: [
        ("America/New_York", 2026, 3, 8),
        ("America/Santiago", 2026, 9, 6),
        ("Europe/Berlin", 2026, 10, 21)
    ])
    func dayLabelsComeFromThePlannedHourOnDSTDays(_ zone: String, _ y: Int, _ m: Int, _ d: Int) {
        let place = FixedZone(zone)
        let f = ReportScreenFixture(now: place.date(y, m, d, 15), calendar: place.calendar)
        #expect(f.screen(.day).chart.bars.map(\.label) == ["12a", "2a", "4a", "6a", "8a", "10a", "12p", "2p", "4p", "6p", "8p", "10p"])
    }

    @Test func dayHasNoGoalAndAnyAmountIsMet() throws {
        let chart = fixture.screen(.day).chart
        try #require(chart.bars.count == 12)
        #expect(chart.goal == nil)
        #expect(chart.bars[4].value == 2)
        #expect(chart.bars[4].metGoal)
        #expect(chart.bars.filter(\.metGoal).count == 1)
    }

    @Test func weekBarsAreMondayToSundayWithTheGoal() {
        let chart = fixture.screen(.week).chart
        #expect(chart.bars.map(\.label) == ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"])
        #expect(chart.bars.map(\.id) == Array(0 ..< 7))
        #expect(chart.bars.map(\.value) == [8, 7.75, 2, 0, 0, 0, 0])
        #expect(chart.goal == 8)
    }

    @Test func weekGoalIsMetAtTheGoalEdge() {
        let bars = fixture.screen(.week).chart.bars
        #expect(bars.map(\.metGoal) == [true, false, false, false, false, false, false])
    }

    @Test func monthLabelsOnlyEveryFifthDayFromTheFirst() throws {
        let bars = fixture.screen(.month).chart.bars
        try #require(bars.count == 31)
        let labelled = bars.filter { !$0.label.isEmpty }
        #expect(labelled.map(\.label) == ["1", "6", "11", "16", "21", "26", "31"])
        #expect(labelled.map(\.id) == [0, 5, 10, 15, 20, 25, 30])
        #expect(bars[18].value == 8)
        #expect(bars[18].metGoal)
        #expect(!bars[19].metGoal)
        #expect(fixture.screen(.month).chart.goal == 8)
    }

    @Test func aZeroGoalHasNoGoalLineAndNothingIsMet() throws {
        var f = fixture
        f.prefs.meditation.slots = []
        let chart = f.screen(.week, selected: .meditation).chart
        try #require(chart.bars.count == 7)
        #expect(chart.goal == nil)
        #expect(chart.bars[0].value == 5)
        #expect(chart.bars.allSatisfy { !$0.metGoal })
    }

    @Test func theChartFollowsTheSelectedHabit() throws {
        let chart = fixture.screen(.week, selected: .meditation).chart
        try #require(chart.bars.count == 7)
        #expect(chart.bars[0].value == 5)
        #expect(chart.goal == 10)
    }
}
