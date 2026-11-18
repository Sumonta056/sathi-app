import AppKit
import SathiCore
import SwiftUI

struct CalendarActivityEdit: Equatable {
    let day: DayKey
    var target: ActivityEditTarget
}

enum CalendarOpen: Equatable {
    case event(CalendarEventForm)
    case activity(CalendarActivityEdit)
}

struct CalendarPopoverTarget: Identifiable {
    let id = UUID()
    let day: DayKey
    let y: CGFloat
    let form: CalendarEventForm
}

struct CalendarPageFocus {
    var popover: CalendarPopoverTarget?
    var editing: CalendarActivityEdit?
}

struct CalendarGridActions {
    var slot: (DayKey, Date, CGFloat) -> Void = { _, _, _ in }
    var block: (DayKey, CalendarBlock, CGFloat) -> Void = { _, _, _ in }
    var toggle: ((ActivityID) -> Void)?
    var failed: (String) -> Void = { _ in }
    var command: () -> Bool = { NSEvent.modifierFlags.contains(.command) }

    func press(_ day: DayKey, _ block: CalendarBlock, _ y: CGFloat) {
        if let toggle, let id = CalendarMergePick.id(of: block), command() {
            toggle(id)
        } else {
            self.block(day, block, y)
        }
    }
}
