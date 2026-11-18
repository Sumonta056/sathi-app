import Foundation

extension Engine {
    static let remindersAppPath = "/System/Applications/Reminders.app"

    package func openReminders() {
        links.open(URL(fileURLWithPath: Self.remindersAppPath))
    }

    package func calendarHoverInfo(_ laid: CalendarLaidBlock, among day: [CalendarLaidBlock]) -> CalendarHoverInfo {
        var lookup = CalendarHoverLookup(now: clock.now, trackerOn: data.prefs.tracker.isOn)
        switch laid.block.source {
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
        return CalendarHoverInfo.make(laid, among: day, lookup: lookup, calendar: calendar)
    }

    package func calendarHoverInfo(_ placed: CalendarPlacedBlock) -> CalendarHoverInfo {
        calendarHoverInfo(Self.laid(placed), among: [])
    }

    private static func laid(_ placed: CalendarPlacedBlock) -> CalendarLaidBlock {
        var half = CalendarHalf.plan
        if case .activity = placed.block.source { half = .actual }
        var out = CalendarLaidBlock(block: placed.block, span: placed.span, half: half, rounded: CalendarRounding.rounded(placed.span))
        out.hidden = placed.hidden.map(Self.laid)
        return out
    }
}
