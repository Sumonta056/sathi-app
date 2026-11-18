import SwiftUI

struct CalendarBlockChrome: ViewModifier {
    let look: CalendarBlockLook
    let radius: CGFloat
    let selected: Bool
    let raised: Bool

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content
            .background(shape.fill(look.fill))
            .overlay(outline(shape))
            .clipShape(shape)
            .background(ring(shape))
    }

    @ViewBuilder private func outline(_ shape: RoundedRectangle) -> some View {
        if selected {
            shape.strokeBorder(Night.tracker, lineWidth: CalendarBlockFit.border(selected: true))
        } else if let stroke = look.stroke {
            shape.strokeBorder(stroke, lineWidth: CalendarBlockFit.border(selected: false))
                .accessibilityIdentifier("calendar.block.outline")
        }
    }

    @ViewBuilder private func ring(_ shape: RoundedRectangle) -> some View {
        if raised {
            shape.fill(Night.card)
                .padding(-UIMetrics.calendarRaisedRing)
                .accessibilityIdentifier("calendar.block.ring")
        }
    }
}
