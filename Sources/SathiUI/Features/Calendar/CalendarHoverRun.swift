import SathiCore
import SwiftUI

@MainActor
struct CalendarHoverRun {
    let engine: Engine
    let grid: CalendarGridActions
    let editTodo: (CalendarHoverTarget) -> Void

    static let shown: [CalendarHoverAction] = [.startAsActivity, .edit, .openInCalendar, .delete, .markDone, .openInReminders, .editAway]

    static func visible(_ info: CalendarHoverInfo) -> [CalendarHoverAction] {
        info.actions.filter(shown.contains)
    }

    func open(row id: String, _ target: CalendarHoverTarget) {
        guard let block = target.row(id) else { return }
        grid.block(target.day, block, target.rect.minY)
    }

    func run(_ action: CalendarHoverAction, _ target: CalendarHoverTarget) {
        let block = target.laid.block
        switch (action, block.source) {
        case let (.startAsActivity, .event(e)):
            engine.startActivity(fromEvent: e.id)
        case let (.openInCalendar, .event(e)):
            engine.openEventInCalendar(e.id)
        case (.edit, .todo):
            editTodo(target)
        case (.edit, _), (.editAway, _):
            grid.block(target.day, block, target.rect.minY)
        case let (.delete, .activity(a, _)):
            if !engine.deleteActivity(a.id) { grid.failed(Copywriter.activitiesDeleteFailed) }
        case let (.markDone, .todo(id)):
            engine.completeCalendarTodo(id)
        case (.openInReminders, _):
            engine.openReminders()
        default:
            break
        }
    }
}
