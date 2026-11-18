import Foundation

extension Engine {
    static let remindersAppPath = "/System/Applications/Reminders.app"

    package func openReminders() {
        links.open(URL(fileURLWithPath: Self.remindersAppPath))
    }

    package func calendarHoverInfo(_ placed: CalendarPlacedBlock) -> CalendarHoverInfo {
        var lookup = CalendarHoverLookup()
        switch placed.block.source {
        case let .event(e):
            let names = calendarPageRead?.readable ?? []
            lookup.calendarNames = Dictionary(names.map { ($0.id, $0.title) }) { first, _ in first }
            if calendarPageForm(for: e).readOnly { lookup.readOnlyEventIDs = [e.id] }
        case let .todo(id):
            let lists = Dictionary(todoSnapshot.lists.map { ($0.id, $0.name) }) { first, _ in first }
            if let listID = todoSnapshot.todos.first(where: { $0.id == id })?.listID { lookup.todoListNames[id] = lists[listID] }
        case .activity:
            break
        }
        return CalendarHoverInfo.make(placed, lookup: lookup, calendar: calendar)
    }
}
