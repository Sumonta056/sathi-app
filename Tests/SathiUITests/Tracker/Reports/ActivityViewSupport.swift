import Foundation
import SathiCore
import SathiTestSupport

enum ActivityViewSupport {
    static let calendar = FixedZone.berlin.calendar

    static func at(_ d: Int, _ h: Int, _ m: Int = 0) -> Date { FixedZone.berlin.date(2026, 3, d, h, m) }

    static func key(_ d: Int) -> DayKey { DayKey(at(d, 12), calendar: calendar) }

    static func item(_ text: String, _ category: String?, _ d: Int, _ from: (Int, Int), _ to: (Int, Int)) -> Activity {
        Activity(text: text, category: category, start: at(d, from.0, from.1), end: at(d, to.0, to.1))
    }

    static let items = [
        item("Fix login bug", "Coding", 4, (9, 0), (10, 30)),
        item("Standup", "Meeting", 4, (11, 0), (11, 30))
    ]

    static func day(_ d: Int = 4, _ list: [Activity] = items) -> ActivityDay {
        ActivityDay(day: key(d), hours: DateInterval(start: at(d, 9), end: at(d, 18)), activities: list)
    }
}

extension ActivityViewSupport {
    static func at(_ d: Int, _ h: Int, _ m: Int, _ s: Int) -> Date {
        at(d, h, m).addingTimeInterval(TimeInterval(s))
    }
}
