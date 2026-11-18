import Foundation

extension Engine {
    static let remindersAppPath = "/System/Applications/Reminders.app"

    package func openReminders() {
        links.open(URL(fileURLWithPath: Self.remindersAppPath))
    }

    package func calendarHoverInfo(_ placed: CalendarPlacedBlock) -> CalendarHoverInfo {
        var lookup = CalendarHoverLookup(now: clock.now, trackerOn: data.prefs.tracker.isOn)
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

    package func calendarHoverInfo(_ laid: CalendarLaidBlock, among day: [CalendarLaidBlock]) -> CalendarHoverInfo {
        var placed = CalendarPlacedBlock(block: laid.block, span: laid.rounded, lane: laid.lane, lanes: laid.lanes, depth: laid.depth)
        placed.hidden = laid.hidden.map { CalendarPlacedBlock(block: $0.block, span: $0.rounded, lane: 0, lanes: 1) }
        return calendarHoverInfo(placed)
    }
}
