import SwiftUI

struct CalendarFloatingPanel<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.cardRadius, style: .continuous)
        content()
            .frame(width: UIMetrics.calendarSideWidth)
            .padding(UIMetrics.calendarSideGap)
            .frame(maxHeight: .infinity, alignment: .top)
            .background(shape.fill(Night.bg))
            .overlay(shape.strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
            .accessibilityIdentifier(MainLayout.floatingIdentifier)
    }
}
