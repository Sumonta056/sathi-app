import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Buddy range builder")
struct BuddyRangeBuilderTests {
    private let zone = FixedZone.berlin
    private let now = FixedZone.berlin.date(2025, 11, 12, 15)

    private func build(
        _ kind: ReportRange = .week,
        events: [HistoryEvent],
        previous: [HistoryEvent] = [],
        prefs: Prefs = Prefs()
    ) -> (totals: [BuddyRangeTotal], bars: [GoalDayBar]) {
        let range = StatsRange.containing(now, kind: kind, calendar: zone.calendar)
        return BuddyRangeBuilder(calendar: zone.calendar).build(
            range: range, now: now, events: events, previousEvents: previous, prefs: prefs
        )
    }

    private func total(_ result: (totals: [BuddyRangeTotal], bars: [GoalDayBar]), _ id: HabitID) -> BuddyRangeTotal {
        result.totals.first { $0.habit == id }!
    }

    @Test func weekTotalsAreSummedInTheGoalUnit() {
        let events: [HistoryEvent] = [
            .done(.water, 3, at: zone.date(2025, 11, 10, 9)),
            .done(.water, 5, at: zone.date(2025, 11, 11, 9)),
            .done(.reading, 20, at: zone.date(2025, 11, 11, 20)),
            .snooze(.water, at: zone.date(2025, 11, 11, 10)),
            .done(.water, 9, at: zone.date(2025, 11, 9, 9))
        ]
        let result = build(events: events)
        #expect(total(result, .water).total == 8)
        #expect(total(result, .reading).total == 20)
        #expect(total(result, .gym).total == 0)
    }

    @Test func changeComparesWithTheCutPreviousWeek() {
        let events = [HistoryEvent.done(.water, 10, at: zone.date(2025, 11, 10, 9))]
        let previous: [HistoryEvent] = [
            .done(.water, 4, at: zone.date(2025, 11, 3, 9)),
            .done(.water, 100, at: zone.date(2025, 11, 5, 20))
        ]
        let result = build(events: events, previous: previous)
        #expect(total(result, .water).change == .up(6))
        #expect(total(result, .reading).change == .none)
    }

    @Test func changeIsDownWhenTheCurrentWeekIsLower() {
        let events = [HistoryEvent.done(.water, 2, at: zone.date(2025, 11, 10, 9))]
        let previous = [HistoryEvent.done(.water, 5, at: zone.date(2025, 11, 3, 9))]
        #expect(total(build(events: events, previous: previous), .water).change == .down(3))
    }

    @Test func daysMetCountsTheDaysUpToTodayThatReachedTheGoal() {
        let events: [HistoryEvent] = [
            .done(.water, 8, at: zone.date(2025, 11, 10, 9)),
            .done(.water, 7, at: zone.date(2025, 11, 11, 9)),
            .done(.water, 8, at: zone.date(2025, 11, 12, 9))
        ]
        let water = total(build(events: events), .water)
        #expect(water.daysMet == 2)
        #expect(water.daysCounted == 3)
    }

    @Test func aDayOffIsNotCountedUnlessItIsMet() {
        var prefs = Prefs()
        prefs.water.daysOff = [DayKey(zone.date(2025, 11, 10), calendar: zone.calendar), DayKey(zone.date(2025, 11, 11), calendar: zone.calendar)]
        let events = [HistoryEvent.done(.water, 8, at: zone.date(2025, 11, 10, 9))]
        let water = total(build(events: events, prefs: prefs), .water)
        #expect(water.daysMet == 1)
        #expect(water.daysCounted == 2)
    }

    @Test func aHabitThatIsOffKeepsItsTotals() {
        var prefs = Prefs()
        prefs.gym.enabled = false
        let events = [HistoryEvent.done(.gym, 15, at: zone.date(2025, 11, 10, 9))]
        let gym = total(build(events: events, prefs: prefs), .gym)
        #expect(gym.isOff)
        #expect(gym.total == 15)
        #expect(!total(build(events: events), .water).isOff)
    }

    @Test func goalDayBarsCountMetAgainstEnabledHabitsAndMarkTheFuture() {
        let events: [HistoryEvent] = [
            .done(.water, 8, at: zone.date(2025, 11, 10, 9)),
            .done(.water, 8, at: zone.date(2025, 11, 11, 9)),
            .done(.reading, 60, at: zone.date(2025, 11, 11, 20))
        ]
        let bars = build(events: events).bars
        #expect(bars.count == 7)
        #expect(bars[0].day == zone.date(2025, 11, 10))
        #expect(bars[0].met == 1)
        #expect(bars[0].of == 2)
        #expect(bars[1].met == 2)
        #expect(bars.map(\.isFuture) == [false, false, false, true, true, true, true])
        #expect(bars[3].met == 0)
    }

    @Test func aDayRangeGivesOneBar() {
        let events = [HistoryEvent.done(.water, 8, at: zone.date(2025, 11, 12, 9))]
        let bars = build(.day, events: events).bars
        #expect(bars.count == 1)
        #expect(bars[0].met == 1)
        #expect(!bars[0].isFuture)
    }
}
