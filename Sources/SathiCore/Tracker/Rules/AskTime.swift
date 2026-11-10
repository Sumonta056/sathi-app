import Foundation

package enum AskTime {
    package static func first(start: Date, length: ActivityLength, offsetMinutes: Int, askEveryMinutes: Int) -> Date {
        guard let span = length.interval else {
            return start.addingTimeInterval(TimeInterval(askEveryMinutes) * Timing.minute)
        }
        return start.addingTimeInterval(span + TimeInterval(offsetMinutes) * Timing.minute)
    }

    package static func awayEnd(start: Date, confirmedUntil: Date, awayStart: Date) -> Date {
        max(start, min(confirmedUntil, awayStart))
    }

    package static func waitedMinutes(shownAt: Date, now: Date) -> Int? {
        let waited = now.timeIntervalSince(shownAt)
        guard waited >= Timing.lateAnswer else { return nil }
        return Int(waited / Timing.minute)
    }
}
