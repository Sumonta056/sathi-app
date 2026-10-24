import Foundation

package struct DayClock: Sendable {
    package var calendar: Calendar

    package init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    package func at(_ minutes: Int, on day: Date) -> Date {
        calendar.date(byAdding: .minute, value: minutes, to: calendar.startOfDay(for: day)) ?? day
    }

    package func minutesOfDay(_ date: Date) -> Int {
        let c = calendar.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }
}
