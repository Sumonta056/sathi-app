import Foundation

package enum SwitchTimes {
    package static func chips(from start: Date, to now: Date, calendar: Calendar) -> [Date] {
        let first = start.wholeSecond
        let last = now.wholeSecond
        guard first < last else { return [last] }
        let step = TimeInterval(Limits.switchStepMinutes) * Timing.minute
        var chips = [first]
        var next = nextMark(after: first, step: step, calendar: calendar)
        while next < last {
            chips.append(next)
            next = next.addingTimeInterval(step)
        }
        chips.append(last)
        return chips
    }

    private static func nextMark(after date: Date, step: TimeInterval, calendar: Calendar) -> Date {
        let dayStart = calendar.startOfDay(for: date)
        let into = date.timeIntervalSince(dayStart)
        let marks = (into / step).rounded(.down) + 1
        return dayStart.addingTimeInterval(marks * step)
    }
}
