import Foundation

extension Copywriter {
    package static func calendarBlockTime(_ span: DateInterval, calendar: Calendar) -> String {
        Fmt.shortRange(span.start, span.end, calendar: calendar) + " · " + calendarBlockLength(span)
    }

    package static func calendarBlockLength(_ span: DateInterval) -> String {
        let total = Int((span.duration / Timing.minute).rounded())
        let (h, m) = (total / Limits.minutesPerHour, total % Limits.minutesPerHour)
        if h == 0 { return "\(m)m" }
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }
}
