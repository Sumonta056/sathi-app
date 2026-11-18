import Foundation

package enum CalendarRounding {
    package static func rounded(_ interval: DateInterval) -> DateInterval {
        let start = rounded(interval.start)
        return DateInterval(start: start, end: max(start, rounded(interval.end)))
    }

    package static func rounded(_ date: Date) -> Date {
        Date(timeIntervalSince1970: (date.timeIntervalSince1970 / Timing.minute).rounded() * Timing.minute)
    }
}
