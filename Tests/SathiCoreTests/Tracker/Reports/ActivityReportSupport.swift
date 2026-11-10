import Foundation
import SathiCore
import SathiTestSupport

enum ActivityReportSupport {
    static let zone = FixedZone.berlin
    static var calendar: Calendar { zone.calendar }

    static func at(_ d: Int, _ h: Int, _ m: Int = 0) -> Date { zone.date(2026, 3, d, h, m) }

    static func dayKey(_ d: Int) -> DayKey { DayKey(at(d, 12), calendar: calendar) }

    static func hours(_ d: Int, from: Int = 9, to: Int = 18) -> DateInterval {
        DateInterval(start: at(d, from), end: at(d, to))
    }

    static func work(
        _ text: String, _ category: String?, _ d: Int, _ from: (Int, Int), _ to: (Int, Int), kind: ActivityKind = .work
    ) -> Activity {
        Activity(kind: kind, text: text, category: category, start: at(d, from.0, from.1), end: at(d, to.0, to.1))
    }

    static func away(_ d: Int, _ from: (Int, Int), _ to: (Int, Int)) -> Activity {
        work("Away", nil, d, from, to, kind: .away)
    }

    static func day(_ d: Int, _ items: [Activity], running: Activity? = nil) -> ActivityDay {
        ActivityDay(day: dayKey(d), hours: hours(d), activities: items, running: running)
    }

    static let busyDay: [Activity] = [
        work("Fix login bug", "Coding", 4, (9, 0), (10, 30)),
        away(4, (10, 30), (11, 0)),
        work("Standup", "Meeting", 4, (11, 30), (12, 0)),
        work("Fix login bug", "Coding", 4, (13, 0), (14, 0)),
        work("Read mail", nil, 4, (14, 0), (14, 20))
    ]
}
