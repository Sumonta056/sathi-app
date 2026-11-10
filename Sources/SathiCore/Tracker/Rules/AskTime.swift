import Foundation

package enum AskTime {
    package static func first(start: Date, length: ActivityLength, offsetMinutes: Int, askEveryMinutes: Int) -> Date {
        let every = start.addingTimeInterval(TimeInterval(askEveryMinutes) * Timing.minute)
        guard let end = lengthEnd(start: start, length: length, offsetMinutes: offsetMinutes) else { return every }
        return min(every, end)
    }

    package static func lengthEnd(start: Date, length: ActivityLength, offsetMinutes: Int) -> Date? {
        length.interval.map { start.addingTimeInterval($0 + TimeInterval(offsetMinutes) * Timing.minute) }
    }

    package static func moved(_ r: RunningActivity, from old: Int, to new: Int, now: Date) -> Date {
        var next = r.askAt.addingTimeInterval(TimeInterval(new - old) * Timing.minute)
        if r.lastAnswer == r.start, let end = lengthEnd(start: r.start, length: r.expectedLength, offsetMinutes: 0) {
            next = min(next, end)
        }
        return max(next, now)
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
