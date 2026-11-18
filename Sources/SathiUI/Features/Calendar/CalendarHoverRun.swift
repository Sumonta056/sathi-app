import SathiCore
import SwiftUI

@MainActor
struct CalendarHoverRun {
    let engine: Engine
    let grid: CalendarGridActions
    let editTodo: (CalendarHoverTarget) -> Void

    static func visible(_ info: CalendarHoverInfo, canMerge: Bool) -> [CalendarHoverAction] {
        info.actions.filter { $0 != .merge || canMerge }
    }

    private func delete(_ id: ActivityID) {
        if !engine.deleteActivity(id) { grid.failed(Copywriter.activitiesDeleteFailed) }
    }

    func open(hidden id: String, _ target: CalendarHoverTarget) {
        guard let hidden = target.placed.hidden.first(where: { $0.block.id == id }) else { return }
        grid.press(target.day, hidden.block, target.rect.minY)
    }

    func run(_ action: CalendarHoverAction, _ target: CalendarHoverTarget) {
        let block = target.placed.block
        switch (action, block.source) {
        case let (.startAsActivity, .event(e)):
            engine.startActivity(fromEvent: e.id)
        case let (.openInCalendar, .event(e)):
            engine.openEventInCalendar(e.id)
        case (.edit, .todo):
            editTodo(target)
        case (.edit, _), (.editAway, _):
            grid.block(target.day, block, target.rect.minY)
        case (.merge, _):
            if let id = CalendarMergePick.id(of: block) { grid.toggle?(id) }
        case let (.delete, .activity(a, _)):
            delete(a.id)
        case let (.markDone, .todo(id)):
            engine.completeCalendarTodo(id)
        case (.openInReminders, _):
            engine.openReminders()
        default:
            break
        }
    }
}
