import Foundation
@testable import SathiCore
import SathiTestSupport
@testable import SathiUI
import Testing

@Suite("Calendar split clock: daylight saving")
struct CalendarSplitClockDaylightTests {
    private static let zone = FixedZone.newYork
    private static let springForward = DayKey(zone.date(2026, 3, 7, 12), calendar: zone.calendar)
    private static let fallBack = DayKey(zone.date(2026, 10, 31, 12), calendar: zone.calendar)
    private static let step: TimeInterval = 30 * 60

    private var cal: Calendar { Self.zone.calendar }

    private func grid(_ day: DayKey) -> CalendarGridLayout {
        CalendarSplitLayout.layout(
            [], days: [day], calendar: cal, rowMinutes: 60,
            metrics: CalendarSplitMetrics.metrics(kind: .day, rowMinutes: 60, narrow: false)
        )
    }

    private func instants(_ day: DayKey) -> [Date] {
        let interval = CalendarPageDay.interval(of: day, calendar: cal)
        return Array(stride(from: interval.start, to: interval.end, by: Self.step))
    }

    @Test(arguments: [(springForward, 23), (fallBack, 25)])
    func thePageDayHasTheRealLength(_ day: DayKey, _ hours: Int) {
        #expect(instants(day).count == hours * 2)
    }

    @Test(arguments: [springForward, fallBack])
    func railLabelsAreTheTwentyFourWallClockHoursFromSixAM(_ day: DayKey) {
        let labels = CalendarSplitClock.labels(grid(day))
        let hours = (0 ..< Limits.calendarGridHours).map { (Limits.calendarPageDayStartHour + $0) % Limits.hoursPerDay }
        #expect(labels.map(\.text) == hours.map { Copywriter.calendarHourLabel(hour: $0) })
        #expect(labels.map(\.row) == Array(0 ..< Limits.calendarGridHours))
    }

    @Test(arguments: [springForward, fallBack])
    func everyInstantSitsInTheRowLabelledWithItsWallClockHour(_ day: DayKey) {
        let g = grid(day)
        let labels = Dictionary(CalendarSplitClock.labels(g).map { ($0.row, $0.text) }) { a, _ in a }
        let wall = Calendar.gregorian(in: cal.timeZone)
        for t in instants(day) {
            let m = CalendarSplitClock.minute(t, day: day, calendar: cal)
            #expect(m == CalendarDayMinutes(day: day, calendar: cal).minute(t))
            let row = g.rows.firstIndex { $0.holds(m) }
            #expect(row.flatMap { labels[$0] } == Copywriter.calendarHourLabel(hour: wall.component(.hour, from: t)))
        }
    }

    @Test(arguments: [springForward, fallBack])
    func aMinuteGoesBackToTheSameWallClockTime(_ day: DayKey) {
        for t in instants(day) {
            let m = CalendarSplitClock.minute(t, day: day, calendar: cal)
            #expect(CalendarSplitClock.minute(CalendarSplitClock.date(minute: m, day: day, calendar: cal), day: day, calendar: cal) == m)
        }
    }

    @Test func theSkippedHourHasNoInstantAndTheRepeatedHourShowsInOneRow() {
        let spring = instants(Self.springForward).map { CalendarSplitClock.minute($0, day: Self.springForward, calendar: cal) }
        #expect(!spring.contains { (1200 ..< 1260).contains($0) })
        let fall = instants(Self.fallBack).map { CalendarSplitClock.minute($0, day: Self.fallBack, calendar: cal) }
        #expect(fall.filter { (1140 ..< 1200).contains($0) }.count == 4)
    }
}
