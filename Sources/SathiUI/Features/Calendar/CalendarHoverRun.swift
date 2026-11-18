import SathiCore
import SwiftUI

@MainActor
struct CalendarHoverRun {
    let engine: Engine
    let grid: CalendarGridActions
    let editTodo: (CalendarHoverTarget) -> Void

    static func visible(_ info: CalendarHoverInfo, canMerge: Bool) -> [CalendarHoverAction] {
        info.actions.filter { ($0 != .merge && $0 != .selectAll) || canMerge }
    }

    private func delete(_ id: ActivityID) {
        if !engine.deleteActivity(id) { grid.failed(Copywriter.activitiesDeleteFailed) }
    }

    func open(row id: String, _ target: CalendarHoverTarget) {
        guard let block = target.placed.row(id) else { return }
        grid.press(target.day, block, target.rect.minY)
    }

    private func pick(_ action: CalendarHoverAction, _ block: CalendarBlock) {
        if action == .selectAll { return grid.select?(block.mergeIDs) ?? () }
        if let id = CalendarMergePick.id(of: block) { grid.toggle?(id) }
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
        case (.merge, _), (.selectAll, _):
            pick(action, block)
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
