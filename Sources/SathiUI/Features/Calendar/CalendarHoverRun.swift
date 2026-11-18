import SathiCore
import SwiftUI

@MainActor
struct CalendarHoverRun {
    let engine: Engine
    let grid: CalendarGridActions
    let editTodo: (CalendarHoverTarget) -> Void

    static func visible(_ info: CalendarHoverInfo, block: CalendarBlock, now: Date, canMerge: Bool) -> [CalendarHoverAction] {
        if case .activity(_, running: true) = block.source { return [] }
        return info.actions.filter { action in
            switch action {
            case .startAsActivity: return now < block.interval.end
            case .merge: return canMerge
            default: return true
            }
        }
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
            engine.deleteActivity(a.id)
        case let (.markDone, .todo(id)):
            engine.completeCalendarTodo(id)
        case (.openInReminders, _):
            engine.openReminders()
        default:
            break
        }
    }
}
