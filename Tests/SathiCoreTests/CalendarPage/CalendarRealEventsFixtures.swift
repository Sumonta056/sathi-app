import Foundation
@testable import SathiCore

enum RealEvents {
    struct Event {
        let date: Int
        let from: String
        let to: String
        let title: String
        let calendar: String

        init(_ date: Int, _ from: String, _ to: String, _ title: String, _ calendar: String) {
            (self.date, self.from, self.to) = (date, from, to)
            (self.title, self.calendar) = (title, calendar)
        }
    }

    static let saturday = 14
    static let friday = 20
    static var days: [DayKey] { (saturday ... friday).map(Split.key) }

    static let list: [Event] = [
        Event(15, "21:00", "21:30", "Air Ticket", "home"),
        Event(16, "10:30", "11:00", "Thomas Message!", "office"),
        Event(16, "13:00", "13:30", "Personal Editorial Scrum", "work"),
        Event(16, "13:00", "13:25", "Personal Editorial scrum", "work"),
        Event(16, "16:30", "17:00", "CCAR-F Workshop Discussion (Domain 2)", "work"),
        Event(16, "18:30", "18:55", "Claude update - What is new and the way forward", "work"),
        Event(17, "13:00", "17:30", "Bangladesh Bank AI Professional Class", "work"),
        Event(17, "17:00", "18:30", "CCAR-F Exam Preparation Workshop", "work"),
        Event(18, "10:06", "10:36", "Friday Java Brief", "learning"),
        Event(18, "10:30", "11:00", "Frontline Morning Scrum", "work"),
        Event(18, "13:00", "13:25", "Personal Editorial scrum", "work"),
        Event(19, "10:00", "10:30", "Vue & Nuxt Friday Brief", "work"),
        Event(19, "10:30", "11:00", "Frontline Morning Scrum", "work"),
        Event(19, "13:00", "13:25", "Personal Editorial scrum", "work"),
        Event(20, "10:15", "10:45", "Agentic Daily 13 Nov 2026", "work"),
        Event(20, "15:00", "15:25", "Personal Editorial scrum", "work"),
        Event(20, "17:00", "18:30", "CCAR-F Exam Preparation Workshop", "work")
    ]

    static var events: [CalendarBlock] {
        list.enumerated().map { i, e in
            let span = Split.span(e.from, e.to, on: e.date)
            let id = "e\(i)"
            let info = CalendarEventInfo(id: id, title: e.title, start: span.start, end: span.end, calendarID: e.calendar)
            return CalendarBlock(
                id: id, title: e.title, interval: span, style: .event(colorHex: 0), source: .event(info),
                isAllDay: false, activityIDs: []
            )
        }
    }

    static var activities: [CalendarBlock] {
        let week: [(Int, [RealWeek.Row])] = [(15, RealWeek.sun), (16, RealWeek.mon), (17, RealWeek.tue), (18, RealWeek.wed)]
        return week.flatMap { date, rows in
            rows.enumerated().map { i, r in
                let start = Split.at(r.from, on: date)
                let end = Split.at(r.to, on: date)
                let a = Activity(kind: r.kind, text: r.text, category: r.category, start: start, end: end)
                return CalendarBlock(
                    id: "a\(date)-\(i)", title: r.kind == .away ? "Away" : r.text, interval: DateInterval(start: start, end: end),
                    style: r.kind == .away ? .away : .activity(category: r.category), source: .activity(a, running: false),
                    isAllDay: false, activityIDs: [a.id]
                )
            }
        }
    }

    static var all: [CalendarBlock] { events + activities }

    static func laid(_ grid: CalendarGridLayout, _ title: String, on date: Int) -> CalendarLaidBlock? {
        grid.days[Split.key(date)]?.first { $0.block.title == title && $0.half == .plan }
    }
}
