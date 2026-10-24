import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("ReportBuilder build")
struct ReportBuilderTests {
    private let zone = FixedZone.berlin
    private var wednesday: Date { zone.date(2026, 3, 4, 15) }

    private func report(_ range: ReportRange, _ events: [HistoryEvent], now: Date? = nil, prefs: Prefs = Prefs()) -> Report {
        ReportBuilder(calendar: zone.calendar).build(range, now: now ?? wednesday, events: events, prefs: prefs)
    }

    private func water(_ range: ReportRange, _ events: [HistoryEvent], now: Date? = nil) -> HabitReport? {
        report(range, events, now: now).habits.first { $0.habit == .water }
    }

    @Test func oneHabitReportPerHabitInOrderWithGoalsFromPrefs() {
        var prefs = Prefs()
        prefs.water.dailyGoalGlasses = 10
        prefs.reading.sessionMinutes = 20
        prefs.meditation.sessionMinutes = 2
        prefs.meditation.slots = [.morning, .afternoon, .evening]
        let r = report(.week, [], prefs: prefs)
        #expect(r.range == .week)
        #expect(r.interval == DateInterval(start: zone.date(2026, 3, 2), end: zone.date(2026, 3, 9)))
        #expect(r.habits.map(\.habit) == HabitID.allCases)
        #expect(r.habits.map(\.goal) == [10, 20, 6])
    }

    @Test(arguments: [
        (ReportRange.day, 2026, 3, 12), (.week, 2026, 3, 7), (.month, 2026, 3, 31),
        (.month, 2026, 2, 28), (.month, 2028, 2, 29), (.month, 2026, 4, 30)
    ])
    func bucketCount(_ range: ReportRange, _ year: Int, _ month: Int, _ count: Int) {
        let r = report(range, [], now: zone.date(year, month, 10, 12))
        #expect(r.habits.count == HabitID.allCases.count)
        #expect(r.habits.allSatisfy { $0.buckets.count == count })
    }

    @Test func dayBucketsAreTwoHoursFromMidnight() throws {
        let buckets = try #require(water(.day, [])?.buckets)
        #expect(buckets.first == ReportBucket(start: zone.date(2026, 3, 4), end: zone.date(2026, 3, 4, 2), total: 0))
        #expect(buckets.last == ReportBucket(start: zone.date(2026, 3, 4, 22), end: zone.date(2026, 3, 5), total: 0))
    }

    @Test func weekBucketsAreDaysFromMonday() throws {
        let buckets = try #require(water(.week, [])?.buckets)
        #expect(buckets.map(\.start) == (0 ..< 7).map { zone.date(2026, 3, 2 + $0) })
        #expect(buckets.map(\.end) == (0 ..< 7).map { zone.date(2026, 3, 3 + $0) })
    }

    @Test func monthBucketsAreCalendarDays() throws {
        let buckets = try #require(water(.month, [])?.buckets)
        #expect(buckets.first?.start == zone.date(2026, 3, 1))
        #expect(buckets.last == ReportBucket(start: zone.date(2026, 3, 31), end: zone.date(2026, 4, 1), total: 0))
    }

    @Test func bucketTotalsIncludeTheStartAndExcludeTheEnd() throws {
        let events: [HistoryEvent] = [
            .done(.water, 1, at: zone.date(2026, 3, 4)),
            .done(.water, 2, at: zone.date(2026, 3, 4, 1, 59)),
            .done(.water, 0.5, at: zone.date(2026, 3, 4, 2)),
            .done(.water, 1, at: zone.date(2026, 3, 4, 15))
        ]
        let w = try #require(water(.day, events))
        #expect(w.buckets.map(\.total) == [3, 0.5, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0])
        #expect(w.total == 4.5)
    }

    @Test func onlyDoneEventsOfThatHabitCount() {
        let at = zone.date(2026, 3, 3, 10)
        let events: [HistoryEvent] = [
            .done(.water, 2, at: at),
            HistoryEvent(date: at, habit: .water, kind: .skip, amount: 3),
            HistoryEvent(date: at, habit: .water, kind: .snooze, amount: 4),
            .done(.reading, 15, at: at),
            .done(.meditation, 5, at: at)
        ]
        let r = report(.week, events)
        #expect(r.habits.map(\.total) == [2, 15, 5])
        #expect(r.habits.map { $0.buckets[1].total } == [2, 15, 5])
    }

    @Test func eventsOutsideTheIntervalAreIgnored() throws {
        let events: [HistoryEvent] = [
            .done(.water, 5, at: zone.date(2026, 3, 1, 23, 59)),
            .done(.water, 1, at: zone.date(2026, 3, 2)),
            .done(.water, 7, at: zone.date(2026, 3, 9)),
            .snooze(.water, at: zone.date(2026, 3, 1, 12)),
            .snooze(.water, at: zone.date(2026, 3, 9, 12))
        ]
        let w = try #require(water(.week, events))
        #expect(w.total == 1)
        #expect(w.buckets.map(\.total).reduce(0, +) == 1)
        #expect(w.snoozes == 0)
    }

    @Test(arguments: [(ReportRange.day, 12.0), (.week, 6.0), (.month, 4.5)])
    func averageDividesByCountedDaysOnly(_ range: ReportRange, _ average: Double) throws {
        let events: [HistoryEvent] = [
            .done(.water, 6, at: zone.date(2026, 3, 2, 10)),
            .done(.water, 6, at: zone.date(2026, 3, 4, 10)),
            .done(.water, 6, at: zone.date(2026, 3, 4, 11))
        ]
        let w = try #require(water(range, events))
        #expect(w.averagePerDay == average)
    }

    @Test(arguments: [(3.0, 13), (12.0, 50), (24.0, 100), (36.0, 100), (0.0, 0)])
    func percentOfGoalIsRoundedAndCappedAt100(_ weekTotal: Double, _ percent: Int) throws {
        let w = try #require(water(.week, [.done(.water, weekTotal, at: zone.date(2026, 3, 3, 9))]))
        #expect(w.percentOfGoal == percent)
    }

    @Test func aFutureDayEventNeverRaisesTheAverage() throws {
        let past = HistoryEvent.done(.water, 6, at: zone.date(2026, 3, 2, 10))
        let future = HistoryEvent.done(.water, 9, at: zone.date(2026, 3, 6, 10))
        let without = try #require(water(.week, [past]))
        let with = try #require(water(.week, [past, future]))
        #expect(with.averagePerDay == 2)
        #expect(with.averagePerDay == without.averagePerDay)
        #expect(with.percentOfGoal == 25)
    }
}
