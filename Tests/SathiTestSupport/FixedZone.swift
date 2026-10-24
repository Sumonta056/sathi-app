import Foundation
import SathiCore

package struct FixedZone {
    package let calendar: Calendar

    package init(_ identifier: String, firstWeekday: Int = 2, calendar kind: Calendar.Identifier = .gregorian) {
        var c = Calendar(identifier: kind)
        c.timeZone = TimeZone(identifier: identifier)!
        c.firstWeekday = firstWeekday
        calendar = c
    }

    package static var berlin: FixedZone { FixedZone("Europe/Berlin") }
    package static var newYork: FixedZone { FixedZone("America/New_York") }
    package static var cairo: FixedZone { FixedZone("Africa/Cairo") }

    package var timeZone: TimeZone { calendar.timeZone }

    package func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    package func adding(days: Int, to date: Date) -> Date {
        calendar.date(byAdding: .day, value: days, to: date)!
    }

    package func doneDays(_ habit: HabitID, _ amount: Double, count: Int, endingAt end: Date) -> [HistoryEvent] {
        (0 ..< count).map { .done(habit, amount, at: adding(days: -$0, to: end)) }
    }

    package func monthLabel(_ date: Date) -> String {
        let c = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", c.year ?? 0, c.month ?? 0)
    }

    package func wallClock(_ date: Date) -> [Int] {
        let c = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return [c.year ?? 0, c.month ?? 0, c.day ?? 0, c.hour ?? 0, c.minute ?? 0]
    }
}
