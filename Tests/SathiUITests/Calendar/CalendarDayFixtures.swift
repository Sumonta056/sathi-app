import Foundation
@testable import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI

enum DayFix {
    static let zone = FixedZone("Asia/Dhaka")
    static var calendar: Calendar { zone.calendar }
    static let wednesday = 18
    static let coding = ActivityCategory(name: "Coding Hobby", colorHex: 0x5FD39A)
    static let categories = [coding]
    static let size = CGSize(width: 320, height: 120)

    static func at(_ h: Int, _ m: Int, _ s: Int = 0, on date: Int = wednesday) -> Date {
        zone.date(2026, 11, date, h, m).addingTimeInterval(TimeInterval(s))
    }

    static func laid(
        _ block: CalendarBlock, half: CalendarHalf, top: Double, bottom: Double
    ) -> CalendarLaidBlock {
        let rounded = CalendarRounding.rounded(block.interval)
        var l = CalendarLaidBlock(block: block, span: rounded, half: half, rounded: rounded)
        l.top = top
        l.bottom = bottom
        return l
    }

    static func activity(
        _ title: String, _ from: Date, _ to: Date, category: String? = "Coding Hobby", eventID: String? = nil,
        kind: ActivityKind = .work, running: Bool = false, top: Double = 0, bottom: Double = 46
    ) -> CalendarLaidBlock {
        let a = Activity(kind: kind, text: title, category: category, start: from, end: to, eventID: eventID)
        let block = CalendarBlock(
            id: "a-" + title, title: kind == .away ? a.awayText : title, interval: DateInterval(start: from, end: to),
            style: kind == .away ? .away : .activity(category: category), source: .activity(a, running: running),
            isAllDay: false, activityIDs: [a.id]
        )
        return laid(block, half: .actual, top: top, bottom: bottom)
    }

    static func away(_ place: String, _ from: Date, _ to: Date, top: Double = 0, bottom: Double = 40) -> CalendarLaidBlock {
        let a = Activity(kind: .away, text: "", start: from, end: to, awayPlaceName: place)
        let block = CalendarBlock(
            id: "away-" + place, title: a.awayText, interval: DateInterval(start: from, end: to),
            style: .away, source: .activity(a, running: false), isAllDay: false, activityIDs: [a.id]
        )
        return laid(block, half: .actual, top: top, bottom: bottom)
    }

    static func event(
        _ title: String, _ from: Date, _ to: Date, colorHex: UInt32 = 0x4285F4, top: Double = 0, bottom: Double = 46
    ) -> CalendarLaidBlock {
        let info = CalendarEventInfo(id: "e-" + title, title: title, start: from, end: to, calendarID: "work")
        let block = CalendarBlock(
            id: info.id, title: title, interval: DateInterval(start: from, end: to), style: .event(colorHex: colorHex),
            source: .event(info), isAllDay: false, activityIDs: []
        )
        return laid(block, half: .plan, top: top, bottom: bottom)
    }

    static func todo(_ title: String, _ due: Date) -> CalendarLaidBlock {
        let block = CalendarBlock(
            id: "t-" + title, title: title, interval: DateInterval(start: due, end: due), style: .todo(colorHex: 0xFF9500),
            source: .todo("t-" + title), isAllDay: false, activityIDs: []
        )
        return laid(block, half: .plan, top: 0, bottom: 22)
    }

    static func card(_ laid: CalendarLaidBlock, calendarName: String? = nil, edit: @escaping () -> Void = {}) -> CalendarDayCard {
        CalendarDayCard(
            laid: laid, size: CGSize(width: size.width, height: laid.bottom - laid.top), calendar: calendar,
            categories: categories, calendarName: calendarName, edit: edit
        )
    }
}
