import Foundation

package struct CalendarGridLayout: Equatable, Sendable {
    package var rows: [CalendarGridRow]
    package var days: [DayKey: [CalendarLaidBlock]]
    package var height: Double
    package var pointsPerMinute: Double

    package init(rows: [CalendarGridRow], days: [DayKey: [CalendarLaidBlock]], height: Double, pointsPerMinute: Double) {
        self.rows = rows
        self.days = days
        self.height = height
        self.pointsPerMinute = pointsPerMinute
    }

    package func y(atMinute minute: Int) -> Double {
        Self.y(minute, rows: rows, pointsPerMinute: pointsPerMinute)
    }

    static func y(_ minute: Int, rows: [CalendarGridRow], pointsPerMinute: Double) -> Double {
        guard let first = rows.first, let last = rows.last else { return 0 }
        if minute < first.startMinute { return first.top }
        guard let r = rows.first(where: { $0.holds(minute) }) else { return last.bottom }
        let offset = Double(minute - r.startMinute)
        return r.isFold
            ? r.top + offset / Double(r.endMinute - r.startMinute) * r.height
            : r.top + offset * pointsPerMinute
    }
}
