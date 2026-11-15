import Foundation

package enum DayOffCellState: Sendable { case pickable, off, unavailable }

package struct DayOffCell: Hashable, Sendable {
    package let key: DayKey
    package let day: Int
    package let state: DayOffCellState
}

package struct DayOffMonth: Equatable, Sendable {
    package let firstDay: DayKey
    package let weeks: [[DayOffCell?]]
    package let canGoBack: Bool
    package let canGoForward: Bool

    static func build(
        first: Date,
        calendar g: Calendar,
        canGoBack: Bool,
        canGoForward: Bool,
        state: (DayKey) -> DayOffCellState
    ) -> DayOffMonth {
        let count = g.range(of: .day, in: .month, for: first)?.count ?? 0
        let blanks = (g.component(.weekday, from: first) - Limits.weekStartWeekday + Limits.daysPerWeek) % Limits.daysPerWeek
        let cells: [DayOffCell?] = Array(repeating: nil, count: blanks) + (1 ... count).map { day in
            let key = DayKey(g.date(byAdding: .day, value: day - 1, to: first) ?? first, calendar: g)
            return DayOffCell(key: key, day: day, state: state(key))
        }
        let padded = cells + Array(repeating: nil, count: (Limits.daysPerWeek - cells.count % Limits.daysPerWeek) % Limits.daysPerWeek)
        let weeks = stride(from: 0, to: padded.count, by: Limits.daysPerWeek).map { Array(padded[$0 ..< $0 + Limits.daysPerWeek]) }
        return DayOffMonth(firstDay: DayKey(first, calendar: g), weeks: weeks, canGoBack: canGoBack, canGoForward: canGoForward)
    }
}

extension HabitDays {
    package func month(offset: Int, now: Date, calendar: Calendar) -> DayOffMonth {
        let g = Calendar.gregorian(in: calendar.timeZone)
        let range = Self.dayOffRange(now: now, calendar: g)
        let today = DayKey(range.lowerBound, calendar: g)
        let last = DayKey(range.upperBound, calendar: g)
        let lastOffset = Self.monthsBetween(range.lowerBound, range.upperBound, g)
        let shown = max(0, min(offset, lastOffset))
        let first = Self.firstOfMonth(shownFrom: range.lowerBound, months: shown, g)
        let isFull = upcoming(from: now, calendar: g).count >= Limits.daysOffMax
        return DayOffMonth.build(first: first, calendar: g, canGoBack: shown > 0, canGoForward: shown < lastOffset) {
            cellState($0, today: today, last: last, isFull: isFull)
        }
    }

    private func cellState(_ key: DayKey, today: DayKey, last: DayKey, isFull: Bool) -> DayOffCellState {
        if key < today || key > last { return .unavailable }
        if daysOff.contains(key) { return .off }
        return isFull ? .unavailable : .pickable
    }

    private static func firstOfMonth(shownFrom date: Date, months: Int, _ g: Calendar) -> Date {
        let start = g.dateComponents([.year, .month], from: date)
        let first = g.date(from: start) ?? date
        return g.date(byAdding: .month, value: months, to: first) ?? first
    }

    private static func monthsBetween(_ a: Date, _ b: Date, _ g: Calendar) -> Int {
        func index(_ d: Date) -> Int {
            let c = g.dateComponents([.year, .month], from: d)
            return (c.year ?? 0) * Limits.monthsPerYear + (c.month ?? 0)
        }
        return index(b) - index(a)
    }
}
