import SathiCore
import SwiftUI

struct CalendarRangeReset: ViewModifier {
    let range: CalendarPageRange
    @Binding var focus: CalendarPageFocus
    @Binding var failure: String?

    func body(content: Content) -> some View {
        content.onChange(of: range) { _ in
            focus = CalendarPageFocus()
            failure = nil
        }
    }
}
