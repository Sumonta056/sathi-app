import SathiCore
import SwiftUI

@MainActor
extension CalendarGridActions {
    static func page(engine: Engine, focus: Binding<CalendarPageFocus>, failure: Binding<String?>) -> CalendarGridActions {
        var a = CalendarGridActions()
        a.slot = { day, slot, y in
            focus.wrappedValue = CalendarPageFocus(popover: CalendarPopoverTarget(
                day: day,
                y: y,
                form: CalendarPage.newEvent(at: slot, engine: engine)
            ))
        }
        a.block = { day, block, y in CalendarPage.tap(block, day: day, y: y, engine: engine, focus: &focus.wrappedValue) }
        a.failed = { failure.wrappedValue = $0 }
        return a
    }
}
