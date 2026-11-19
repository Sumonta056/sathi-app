import Foundation
@testable import SathiCore

enum Lay {
    static let t0 = Date(timeIntervalSince1970: 1_800_000_000)

    static func at(_ minute: Int) -> Date {
        t0.addingTimeInterval(TimeInterval(minute * 60))
    }

    static func span(_ from: Int, _ to: Int) -> DateInterval {
        DateInterval(start: at(from), end: at(to))
    }

    static func event(_ id: String, _ from: Int, _ to: Int) -> CalendarBlock {
        CalendarBlock(
            id: id, title: id, interval: span(from, to), style: .event(colorHex: 0),
            source: .event(CalendarEventInfo(id: id, title: id, start: at(from), end: at(to), calendarID: "c")),
            isAllDay: false, activityIDs: []
        )
    }

    static func activity(_ id: String, _ from: Int, _ to: Int) -> CalendarBlock {
        let a = Activity(text: id, start: at(from), end: at(to))
        return CalendarBlock(
            id: id, title: id, interval: span(from, to), style: .activity(category: nil),
            source: .activity(a, running: false), isAllDay: false, activityIDs: [a.id]
        )
    }
}
