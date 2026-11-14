import SathiCore
import SwiftUI

struct CalendarRangeReset: ViewModifier {
    let range: CalendarPageRange
    @Binding var focus: CalendarPageFocus
    @Binding var selected: Set<ActivityID>
    @Binding var error: String?
    let clearUndo: () -> Void

    func body(content: Content) -> some View {
        content.onChange(of: range) { _ in
            focus = CalendarPageFocus()
            selected = []
            error = nil
            clearUndo()
        }
    }
}

struct CalendarSelectionPrune: ViewModifier {
    let blocks: [CalendarBlock]
    @Binding var selected: Set<ActivityID>
    @Binding var error: String?

    func body(content: Content) -> some View {
        content.onChange(of: blocks) { blocks in
            let kept = CalendarMergePick.pruned(selected, in: CalendarMergePick.rows(blocks))
            guard kept != selected else { return }
            selected = kept
            error = nil
        }
    }
}
