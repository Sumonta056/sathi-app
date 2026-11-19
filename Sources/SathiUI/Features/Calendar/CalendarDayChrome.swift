import SwiftUI

struct CalendarDayChrome: ViewModifier {
    let size: CGSize
    var padding = UIMetrics.calendarDayCardPadding
    let fill: Color
    let edge: Color
    var outline: Color?
    var stripes = false

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.calendarDayCardRadius, style: .continuous)
        content
            .padding(padding)
            .frame(width: max(0, size.width), height: max(0, size.height), alignment: .topLeading)
            .background {
                ZStack {
                    fill
                    if stripes { CalendarDayStripes() }
                }
            }
            .overlay(alignment: .leading) { edge.frame(width: UIMetrics.calendarDayCardEdge) }
            .clipShape(shape)
            .overlay(shape.strokeBorder(outline ?? .clear, lineWidth: UIMetrics.calendarDayEventOutline))
    }
}

struct CalendarDayStripes: View {
    var body: some View {
        Canvas { ctx, size in
            var path = Path()
            var x = -size.height
            while x < size.width {
                path.move(to: CGPoint(x: x, y: size.height))
                path.addLine(to: CGPoint(x: x + size.height, y: 0))
                x += UIMetrics.calendarStripeSpacing
            }
            let ink = Night.calendarAway.opacity(UIMetrics.calendarDayAwayStripeOpacity)
            ctx.stroke(path, with: .color(ink), lineWidth: UIMetrics.calendarStripeWidth)
        }
        .allowsHitTesting(false)
    }
}
