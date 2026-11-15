import Foundation
import SathiCore

enum TodoMapping {
    static func access(notDetermined: Bool, granted: Bool) -> TodoAccess {
        if notDetermined { return .notAsked }
        return granted ? .allowed : .denied
    }

    static func due(from c: DateComponents, calendar: Calendar) -> TodoDue? {
        guard let year = c.year, let month = c.month, let day = c.day else { return nil }
        let timed = c.hour != nil
        var parts = DateComponents(year: year, month: month, day: day)
        if timed {
            parts.hour = c.hour
            parts.minute = c.minute ?? 0
        }
        guard let date = calendar.date(from: parts) else { return nil }
        return TodoDue(date: timed ? date : calendar.startOfDay(for: date), hasTime: timed)
    }

    static func components(for due: TodoDue, calendar: Calendar) -> DateComponents {
        let units: Set<Calendar.Component> = due.hasTime ? [.year, .month, .day, .hour, .minute] : [.year, .month, .day]
        var c = calendar.dateComponents(units, from: due.date)
        c.calendar = calendar
        c.timeZone = due.hasTime ? calendar.timeZone : nil
        return c
    }

    static func colorHex(red: Double, green: Double, blue: Double) -> String {
        func byte(_ v: Double) -> Int { Int((min(max(v, 0), 1) * 255).rounded()) }
        return String(format: "#%02X%02X%02X", byte(red), byte(green), byte(blue))
    }

    static func rgb(fromHex hex: String) -> (red: Double, green: Double, blue: Double)? {
        let digits = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard digits.count == 6, let v = UInt32(digits, radix: 16) else { return nil }
        return (Double((v >> 16) & 0xFF) / 255, Double((v >> 8) & 0xFF) / 255, Double(v & 0xFF) / 255)
    }

    static func sorted(_ lists: [TodoList]) -> [TodoList] {
        lists.sorted {
            let byAccount = $0.accountName.localizedCompare($1.accountName)
            if byAccount != .orderedSame { return byAccount == .orderedAscending }
            return $0.name.localizedCompare($1.name) == .orderedAscending
        }
    }
}
