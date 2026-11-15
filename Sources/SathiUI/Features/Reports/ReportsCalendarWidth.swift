import SwiftUI

struct ReportsCalendarWidth: ViewModifier {
    @Environment(\.mainLayout) private var layout

    func body(content: Content) -> some View {
        if layout.isNarrow {
            content.frame(maxWidth: .infinity)
        } else {
            content.frame(width: UIMetrics.reportsCalendarWidth)
        }
    }
}

extension View {
    func reportsCalendarWidth() -> some View { modifier(ReportsCalendarWidth()) }
}
