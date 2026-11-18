import SathiCore
import SwiftUI

@MainActor
extension CalendarGridActions {
    static func page(
        kind: ReportRange, engine: Engine, focus: Binding<CalendarPageFocus>,
        selected: Binding<Set<ActivityID>>, error: Binding<String?>
    ) -> CalendarGridActions {
        var a = CalendarGridActions()
        a.slot = { day, slot, y in
            focus.wrappedValue = CalendarPageFocus(popover: CalendarPopoverTarget(
                day: day,
                y: y,
                form: CalendarPage.newEvent(at: slot, engine: engine)
            ))
        }
        a.block = { day, block, y in CalendarPage.tap(block, day: day, y: y, engine: engine, focus: &focus.wrappedValue) }
        a.failed = { error.wrappedValue = $0 }
        if kind == .day {
            a.toggle = { id in
                CalendarMergePick.toggle(id, in: &selected.wrappedValue)
                error.wrappedValue = nil
            }
            a.select = { ids in
                selected.wrappedValue.formUnion(ids)
                error.wrappedValue = nil
            }
        }
        return a
    }
}
