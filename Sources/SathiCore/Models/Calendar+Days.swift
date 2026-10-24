import Foundation

extension Calendar {
    package static func gregorian(in timeZone: TimeZone) -> Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = timeZone
        return c
    }

    func nextDay(after day: Date) -> Date {
        dateInterval(of: .day, for: day)?.end ?? day
    }

    func previousDay(before day: Date) -> Date {
        dateInterval(of: .day, for: startOfDay(for: day).addingTimeInterval(-Timing.second))?.start ?? day
    }

    func stepDays(_ count: Int, from day: Date) -> Date {
        var d = startOfDay(for: day)
        for _ in 0 ..< abs(count) {
            d = count > 0 ? nextDay(after: d) : previousDay(before: d)
        }
        return d
    }
}
