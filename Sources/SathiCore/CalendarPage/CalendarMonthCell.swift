import Foundation

package struct CalendarMonthCell: Equatable, Sendable {
    package var day: DayKey
    package var chips: [CalendarBlock]
    package var more: Int
    package var tracked: TimeInterval
    package var isToday: Bool
    package var inRange: Bool

    package static func cells(
        range: CalendarPageRange,
        blocks: [CalendarBlock],
        activities: [Activity],
        today: DayKey,
        calendar: Calendar
    ) -> [[CalendarMonthCell]] {
        let g = Calendar.gregorian(in: calendar.timeZone)
        let events = blocks.filter(isEvent).sorted { ($0.isAllDay ? 0 : 1, $0.interval.start) < ($1.isAllDay ? 0 : 1, $1.interval.start) }
        return range.monthWeeks.map { week in
            week.map { day in
                let inRange = range.inRange(day)
                let page = CalendarPageDay.interval(of: day, calendar: g)
                let dated = DateInterval(start: day.start(in: g), end: g.nextDay(after: day.start(in: g)))
                let onDay = inRange ? events.filter { overlaps($0, $0.isAllDay ? dated : page) } : []
                return CalendarMonthCell(
                    day: day,
                    chips: Array(onDay.prefix(Limits.calendarMonthChipsShown)),
                    more: max(0, onDay.count - Limits.calendarMonthChipsShown),
                    tracked: inRange ? CalendarPageStats.tracked(activities, in: page) : 0,
                    isToday: day == today,
                    inRange: inRange
                )
            }
        }
    }

    private static func isEvent(_ block: CalendarBlock) -> Bool {
        switch block.source {
        case .event, .todo: return true
        case .activity: return false
        }
    }

    private static func overlaps(_ block: CalendarBlock, _ interval: DateInterval) -> Bool {
        let i = block.interval
        if i.duration == 0 { return interval.start <= i.start && i.start < interval.end }
        return i.start < interval.end && i.end > interval.start
    }
}
