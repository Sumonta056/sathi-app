import SathiCore
import SwiftUI

struct CalendarBlockContext {
    var texts: [String: CalendarBlockText] = [:]
    var categories: [ActivityCategory] = []
    var selected: Set<ActivityID> = []
    var press: (CalendarBlock, CGFloat) -> Void = { _, _ in }
    var hover: (CalendarPlacedBlock, Bool) -> Void = { _, _ in }

    func text(_ block: CalendarBlock) -> CalendarBlockText {
        texts[block.id] ?? CalendarBlockText(time: "", spoken: block.title)
    }

    func isSelected(_ block: CalendarBlock) -> Bool {
        CalendarMergePick.id(of: block).map(selected.contains) ?? false
    }
}
