import Foundation

extension StatsRange {
    package func comparable(now: Date, calendar: Calendar) -> DateInterval {
        let before = previous.interval
        guard holds(now) else { return before }
        let cal = Calendar.gregorian(in: calendar.timeZone)
        let today = cal.startOfDay(for: now)
        let wholeDays = days.filter { $0.start < today }.count
        let clock = now.timeIntervalSince(today)
        let cut = cal.stepDays(wholeDays, from: before.start).addingTimeInterval(clock)
        return DateInterval(start: before.start, end: min(cut, before.end))
    }
}
