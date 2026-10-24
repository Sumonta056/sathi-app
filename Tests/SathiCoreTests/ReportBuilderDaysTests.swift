import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("ReportBuilder days")
struct ReportBuilderDaysTests {
    private let zone = FixedZone.berlin
    private var wednesday: Date { zone.date(2026, 3, 4, 15) }

    private func habit(_ id: HabitID, _ range: ReportRange, _ events: [HistoryEvent], prefs: Prefs = Prefs()) -> HabitReport? {
        ReportBuilder(calendar: zone.calendar).build(range, now: wednesday, events: events, prefs: prefs).habits.first { $0.habit == id }
    }

    @Test func aGoalOfZeroGivesZeroPercentAndNoDaysMet() throws {
        var prefs = Prefs()
        prefs.meditation.slots = []
        let m = try #require(habit(.meditation, .week, [.done(.meditation, 5, at: zone.date(2026, 3, 3, 8))], prefs: prefs))
        #expect(m.goal == 0)
        #expect(m.total == 5)
        #expect(m.percentOfGoal == 0)
        #expect(m.daysMet == 0)
    }

    @Test func daysMetCountsCountedDaysAtOrAboveTheGoal() {
        let events: [HistoryEvent] = [
            .done(.water, 8, at: zone.date(2026, 3, 2, 10)),
            .done(.water, 7.75, at: zone.date(2026, 3, 3, 10)),
            .done(.water, 5, at: zone.date(2026, 3, 4, 9)),
            .done(.water, 4, at: zone.date(2026, 3, 4, 14))
        ]
        #expect(habit(.water, .week, events)?.daysMet == 2)
        #expect(habit(.water, .month, events)?.daysMet == 2)
        #expect(habit(.water, .day, events)?.daysMet == 1)
    }

    @Test func daysMetSumsAllDoneEventsOfADay() {
        let events = (0 ..< 8).map { HistoryEvent.done(.water, 1, at: zone.date(2026, 3, 3, 9 + $0)) }
        #expect(habit(.water, .week, events)?.daysMet == 1)
    }

    @Test func bestDayIsTheEarliestDayWithTheHighestTotal() {
        let events: [HistoryEvent] = [
            .done(.water, 5, at: zone.date(2026, 3, 2, 10)),
            .done(.water, 9, at: zone.date(2026, 3, 3, 10)),
            .done(.water, 4, at: zone.date(2026, 3, 4, 9)),
            .done(.water, 5, at: zone.date(2026, 3, 4, 14))
        ]
        #expect(habit(.water, .week, events)?.bestDay == zone.date(2026, 3, 3))
        #expect(habit(.water, .month, events)?.bestDay == zone.date(2026, 3, 3))
    }

    @Test func bestDayIsNilWhenNothingWasDone() {
        let events: [HistoryEvent] = [.snooze(.water, at: zone.date(2026, 3, 3, 10)), .done(.reading, 15, at: zone.date(2026, 3, 3, 22))]
        #expect(habit(.water, .week, events)?.bestDay == nil)
        #expect(habit(.reading, .week, events)?.bestDay == zone.date(2026, 3, 3))
    }

    @Test func bestDayOfADayReportIsThatDay() {
        let events: [HistoryEvent] = [.done(.water, 1, at: zone.date(2026, 3, 4, 9))]
        #expect(habit(.water, .day, events)?.bestDay == zone.date(2026, 3, 4))
    }

    @Test func snoozesCountOnlyThatHabitInsideTheInterval() {
        let events: [HistoryEvent] = [
            .snooze(.water, at: zone.date(2026, 3, 2, 11)),
            .snooze(.water, at: zone.date(2026, 3, 4, 12)),
            .snooze(.water, at: zone.date(2026, 2, 28, 12)),
            .snooze(.reading, at: zone.date(2026, 3, 3, 22)),
            .skip(.water, at: zone.date(2026, 3, 3, 12))
        ]
        #expect(habit(.water, .week, events)?.snoozes == 2)
        #expect(habit(.reading, .week, events)?.snoozes == 1)
        #expect(habit(.meditation, .week, events)?.snoozes == 0)
        #expect(habit(.water, .day, events)?.snoozes == 1)
    }
}
