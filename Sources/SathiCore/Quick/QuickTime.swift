import Foundation

package enum QuickTime: Equatable, Sendable {
    case inMinutes(Int)
    case at(minutes: Int)

    package func date(now: Date, calendar: Calendar) -> Date {
        switch self {
        case let .inMinutes(n):
            return now.wholeSecond.addingTimeInterval(Double(max(n, 1)) * Timing.minute)
        case let .at(minutes):
            let clock = DayClock(calendar: calendar)
            let minute = min(max(minutes, 0), Limits.minutesPerDay - 1)
            var day = now
            var candidate = clock.at(minute, on: day)
            while candidate <= now {
                day = calendar.nextDay(after: day)
                candidate = clock.at(minute, on: day)
            }
            return candidate
        }
    }
}

package enum QuickAddResult: Equatable, Sendable {
    case added(UUID)
    case empty
    case full
}

package enum QuickText {
    package static func clean(_ raw: String) -> String {
        let joined = String(raw.map { $0.isNewline ? " " : $0 })
        let trimmed = joined.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(trimmed.prefix(Limits.quickTextMax))
    }
}
