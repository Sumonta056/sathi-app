import Foundation

extension TodoDue {
    package static func make(hasDate: Bool, date: Date, minutes: Int?, calendar: Calendar) -> TodoDue? {
        guard hasDate else { return nil }
        let start = calendar.startOfDay(for: date)
        guard let minutes else { return TodoDue(date: start, hasTime: false) }
        let at = calendar.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: start) ?? start
        return TodoDue(date: at, hasTime: true)
    }

    package func minutes(calendar: Calendar) -> Int? {
        guard hasTime else { return nil }
        let c = calendar.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }
}
