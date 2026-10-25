import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("ReportScreen tiles")
struct ReportScreenTileTests {
    private var fixture: ReportScreenFixture {
        var f = ReportScreenFixture.at(2026, 10, 20, 15)
        f.events = [
            .done(.water, 7, at: ReportScreenFixture.on(2026, 10, 19)),
            .done(.water, 8, at: ReportScreenFixture.on(2026, 10, 20)),
            .done(.reading, 10, at: ReportScreenFixture.on(2026, 10, 19, 21)),
            .done(.reading, 15, at: ReportScreenFixture.on(2026, 10, 20, 21))
        ]
        f.enabled = [.water, .reading]
        return f
    }

    private func tile(_ range: ReportRange, _ habit: HabitID) throws -> ReportTile {
        try #require(fixture.screen(range).tiles.first { $0.habit == habit })
    }

    @Test func oneTilePerHabitInOrderWithUppercasedLabels() {
        let tiles = fixture.screen(.week).tiles
        #expect(tiles.map(\.habit) == HabitID.allCases)
        #expect(tiles.map(\.label) == ["WATER", "READING", "MEDITATION"])
        #expect(tiles.map(\.id) == HabitID.allCases)
    }

    @Test func weekWaterShowsTheAveragePerDayWithOneDecimal() throws {
        let water = try tile(.week, .water)
        #expect(water.value == "7.5")
        #expect(water.unit == "glasses / day")
        #expect(water.percent == 94)
        #expect(water.note == "94% of your daily goal")
        #expect(!water.isOff)
    }

    @Test func weekReadingShowsTheRoundedAveragePerDay() throws {
        let reading = try tile(.week, .reading)
        #expect(reading.value == "13")
        #expect(reading.unit == "min / day")
        #expect(reading.percent == 83)
        #expect(reading.note == "83% of your daily goal")
    }

    @Test func dayTilesShowTodaysTotal() throws {
        let water = try tile(.day, .water)
        #expect(water.value == "8.0")
        #expect(water.unit == "glasses today")
        #expect(water.note == "100% of your daily goal")
        let reading = try tile(.day, .reading)
        #expect(reading.value == "15")
        #expect(reading.unit == "min today")
    }

    @Test func monthTilesUseTheAveragePerDay() throws {
        let water = try tile(.month, .water)
        #expect(water.percent == 9)
        #expect(water.note == "9% of your daily goal")
        #expect(water.unit == "glasses / day")
    }

    @Test func anOffHabitIsMarkedOffWithAnOffNote() throws {
        let meditation = try tile(.week, .meditation)
        #expect(meditation.isOff)
        #expect(meditation.note == "Off")
        #expect(meditation.value == "0")
        #expect(meditation.unit == "min / day")
    }

    @Test func anOffHabitKeepsItsHistoryInItsTile() throws {
        var f = fixture
        f.enabled = [.reading]
        let water = try #require(f.screen(.week).tiles.first { $0.habit == .water })
        #expect(water.isOff)
        #expect(water.value == "7.5")
        #expect(water.note == "Off")
    }

    @Test func anEnabledSelectionIsKept() {
        #expect(fixture.screen(.week, selected: .reading).selected == .reading)
    }

    @Test(arguments: [
        ([HabitID.reading], HabitID.reading),
        ([.reading, .meditation], .reading),
        ([.meditation], .meditation),
        ([.water, .meditation], .water)
    ])
    func anOffSelectionFallsBackToTheFirstEnabledHabit(_ enabled: [HabitID], _ expected: HabitID) {
        var f = fixture
        f.enabled = Set(enabled)
        let selected: HabitID = enabled.contains(.water) ? .reading : .water
        #expect(f.screen(.week, selected: selected).selected == expected)
    }

    @Test func nothingEnabledFallsBackToWater() {
        var f = fixture
        f.enabled = []
        let screen = f.screen(.week, selected: .reading)
        #expect(screen.selected == .water)
        #expect(screen.chart.title == "Water · this week")
    }

    @Test func theChartFollowsTheFallbackHabit() {
        var f = fixture
        f.enabled = [.reading]
        #expect(f.screen(.week, selected: .water).chart.title == "Reading · this week")
    }
}
