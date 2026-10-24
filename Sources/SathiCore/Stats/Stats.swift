import Foundation

package struct Stats: Sendable {
    package var calendar: Calendar

    package init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    package func total(_ id: HabitID, on day: Date, in events: [HistoryEvent]) -> Double {
        events.reduce(0) { sum, e in
            e.habit == id && e.kind == .done && calendar.isDate(e.date, inSameDayAs: day) ? sum + e.amount : sum
        }
    }
}
