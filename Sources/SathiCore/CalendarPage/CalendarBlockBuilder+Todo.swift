import Foundation

extension CalendarBlockBuilder {
    package static func todoBlocks(
        _ todos: [Todo],
        colors: [String: UInt32],
        interval: DateInterval,
        calendar: Calendar
    ) -> [CalendarBlock] {
        todos.compactMap { todo in
            guard !todo.isDone, let due = todo.due else { return nil }
            let start = due.hasTime ? due.date : calendar.startOfDay(for: due.date)
            let from = due.hasTime ? interval.start : calendar.startOfDay(for: interval.start)
            let to = due.hasTime ? interval.end : calendar.startOfDay(for: interval.end)
            guard start >= from, start < to else { return nil }
            return CalendarBlock(
                id: "t-" + todo.id,
                title: todo.title,
                interval: DateInterval(start: start, end: start),
                style: .todo(colorHex: colors[todo.listID] ?? 0),
                source: .todo(todo.id),
                isAllDay: !due.hasTime,
                activityIDs: []
            )
        }
    }
}
