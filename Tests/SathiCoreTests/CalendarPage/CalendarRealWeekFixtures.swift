import Foundation
@testable import SathiCore

enum RealWeek {
    struct Row {
        let from: String
        let to: String
        let kind: ActivityKind
        let text: String
        let category: String?

        init(_ from: String, _ to: String, _ kind: ActivityKind, _ text: String, _ category: String?) {
            (self.from, self.to, self.kind, self.text) = (from, to, kind, text)
            self.category = category
        }
    }

    typealias Plan = (from: String, to: String, title: String)

    static let column = DateInterval(start: Lay.t0, duration: Timing.day)

    static func at(_ clock: String) -> Date {
        let parts = clock.split(separator: ":").compactMap { Double($0) }
        let hours = parts[0] < Double(Limits.calendarPageDayStartHour) ? parts[0] + Double(Limits.hoursPerDay) : parts[0]
        let seconds = (hours - Double(Limits.calendarPageDayStartHour)) * Timing.hour + parts[1] * Timing.minute + parts[2]
        return column.start.addingTimeInterval(seconds)
    }

    static func blocks(_ rows: [Row], _ plans: [Plan]) -> [CalendarBlock] {
        let activities = rows.map {
            Activity(kind: $0.kind, text: $0.text, category: $0.category, start: at($0.from), end: at($0.to))
        }
        let events = plans.map {
            CalendarEventInfo(id: $0.title, title: $0.title, start: at($0.from), end: at($0.to), calendarID: "work")
        }
        return CalendarBlockBuilder.blocks(events: events, activities: activities, running: nil, colors: [:], joins: true)
    }

    static let sun: [Row] = [
        Row("07:00:00", "07:20:42", .away, "", nil), Row("07:21:16", "08:25:51", .work, "Sathi R&D", "Hobby"),
        Row("08:25:51", "08:34:51", .away, "", nil), Row("08:35:01", "08:37:21", .work, "Sathi R&D", "Hobby"),
        Row("08:37:21", "08:43:13", .away, "", nil), Row("08:43:22", "09:30:54", .work, "Sathi R&D", "Hobby"),
        Row("09:30:54", "10:00:37", .work, "Cleaning", "Home"), Row("10:00:37", "10:16:56", .buddy, "Reading", "Reading"),
        Row("10:16:56", "10:26:56", .buddy, "Reading", "Reading"), Row("10:27:10", "10:44:21", .work, "Learning", "Learning"),
        Row("10:44:21", "11:14:50", .work, "Sathi R&D", "Hobby"), Row("11:14:50", "11:57:09", .work, "File Extension", "Hobby"),
        Row("11:57:09", "12:12:29", .work, "Break", "Break"), Row("12:12:29", "13:50:00", .work, "Practice", "Learning"),
        Row("13:50:00", "16:14:46", .away, "", nil), Row("16:14:58", "18:40:59", .work, "Practice", "Learning"),
        Row("18:43:50", "19:37:04", .away, "", nil), Row("19:37:25", "20:08:07", .work, "Practice", "Learning"),
        Row("20:08:07", "21:33:49", .work, "Slides", "Learning"), Row("21:33:49", "21:38:49", .buddy, "Stretch", "Gym"),
        Row("21:38:52", "22:19:09", .work, "Slides", "Learning"), Row("22:55:44", "22:59:35", .away, "", nil),
        Row("23:00:00", "23:30:00", .away, "", nil)
    ]

    static let mon: [Row] = [
        Row("07:00:00", "09:30:49", .away, "", nil), Row("09:31:37", "09:37:58", .work, "Starting the day", "Browsing"),
        Row("09:37:58", "09:42:58", .buddy, "Stretch", "Gym"), Row("09:43:02", "09:48:08", .work, "Starting the day", "Browsing"),
        Row("09:48:08", "10:18:12", .work, "Slides", "Learning"), Row("10:18:12", "10:20:14", .away, "", nil),
        Row("10:22:01", "10:30:00", .work, "Testing", "Client"), Row("10:30:00", "11:00:07", .work, "Message", "Office"),
        Row("11:00:07", "12:51:38", .work, "Testing", "Client"), Row("12:51:38", "12:55:43", .away, "", nil),
        Row("12:55:55", "13:01:36", .work, "Testing", "Client"), Row("13:01:36", "13:14:06", .work, "Scrum", "Meeting"),
        Row("13:14:06", "14:33:40", .away, "", nil), Row("14:35:54", "15:01:32", .work, "Testing", "Client"),
        Row("15:01:32", "15:06:16", .away, "", nil), Row("15:06:22", "15:08:50", .work, "Testing", "Client"),
        Row("15:08:50", "15:10:00", .away, "", nil), Row("15:10:07", "15:35:27", .work, "Testing", "Client"),
        Row("15:35:27", "15:39:24", .away, "", nil), Row("15:41:12", "16:23:49", .work, "Testing", "Client"),
        Row("16:23:49", "16:26:09", .away, "", nil), Row("16:26:24", "16:31:56", .work, "Slides", "Learning"),
        Row("16:33:23", "16:55:33", .work, "Workshop", "Meetings"), Row("16:56:38", "17:33:33", .work, "Slides", "Learning"),
        Row("17:33:33", "17:35:44", .away, "", nil), Row("17:35:46", "17:38:45", .away, "", nil),
        Row("17:39:00", "17:44:12", .work, "Slides", "Learning"), Row("17:44:12", "20:47:26", .away, "", nil),
        Row("20:47:52", "21:54:37", .work, "Demo", "Learning"), Row("21:54:37", "23:30:00", .away, "", nil)
    ]

    static let monPlans: [Plan] = [
        ("13:00:00", "13:30:00", "Scrum call"), ("16:30:00", "17:00:00", "Exam workshop"),
        ("18:30:00", "19:00:00", "Product update")
    ]

    static let tue: [Row] = [
        Row("07:00:00", "09:20:21", .away, "", nil), Row("09:20:37", "09:42:56", .work, "Demo", "Learning"),
        Row("09:42:56", "09:51:32", .away, "", nil), Row("09:51:46", "09:58:22", .work, "Demo", "Learning"),
        Row("09:58:22", "23:30:00", .away, "", nil)
    ]

    static let tuePlans: [Plan] = [("13:00:00", "17:30:00", "AI class"), ("17:00:00", "18:30:00", "Exam workshop")]

    static let wed: [Row] = [
        Row("07:00:00", "09:34:28", .away, "", nil), Row("09:34:28", "09:37:13", .work, "Away", "Break"),
        Row("09:37:13", "10:38:16", .work, "Starting the day", "Browsing"), Row("10:38:16", "12:30:57", .work, "Code review", "Hobby"),
        Row("12:30:57", "12:35:57", .buddy, "Stretch", "Gym"), Row("12:36:00", "13:06:29", .work, "Code review", "Hobby"),
        Row("13:06:29", "13:39:13", .work, "Scrum", "Meeting"), Row("13:39:13", "14:14:02", .work, "Bath", "Break"),
        Row("14:14:02", "14:29:02", .work, "Lunch", "Break"), Row("14:46:44", "16:40:19", .away, "", nil)
    ]

    static let wedPlans: [Plan] = [
        ("09:45:00", "10:15:00", "Friday brief"), ("10:15:00", "10:45:00", "Morning standup"),
        ("13:00:00", "13:30:00", "Scrum call")
    ]
}
