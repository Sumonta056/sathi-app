import SwiftUI

struct CalendarStripes: View {
    var color = Night.calendarAway.opacity(UIMetrics.calendarStripeOpacity)

    var body: some View {
        Canvas { ctx, size in
            var path = Path()
            var x = -size.height
            while x < size.width {
                path.move(to: CGPoint(x: x, y: size.height))
                path.addLine(to: CGPoint(x: x + size.height, y: 0))
                x += UIMetrics.calendarStripeSpacing
            }
            ctx.stroke(path, with: .color(color), lineWidth: UIMetrics.calendarStripeWidth)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
