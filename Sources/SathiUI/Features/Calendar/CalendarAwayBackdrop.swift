import SathiCore
import SwiftUI

struct CalendarAwayBackdrop: View {
    enum Layer { case all, stripes, label }

    let block: CalendarBlock
    let text: CalendarBlockText
    let height: CGFloat
    var layer = Layer.all
    var selected = false
    let open: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.calendarBlockRadius, style: .continuous)
        ZStack(alignment: .topTrailing) {
            if layer != .label {
                stripes
                    .background(Night.calendarAway.opacity(UIMetrics.calendarAwayFillOpacity))
                    .clipShape(shape)
                    .allowsHitTesting(false)
            }
            if layer != .stripes { label }
        }
        .frame(maxWidth: .infinity, alignment: .topTrailing)
        .frame(height: max(height, UIMetrics.calendarBarMinHeight), alignment: .top)
    }

    private var label: some View {
        Button(action: open) {
            Text(verbatim: block.title)
                .font(Typography.tracker(UIMetrics.calendarBlockTimeFont, .semibold))
                .foregroundStyle(Night.muted)
                .lineLimit(1)
                .padding(UIMetrics.calendarCopiesPadding)
                .frame(maxHeight: min(height, UIMetrics.calendarAwayLabelHeight))
                .background(Capsule().fill(Night.calendarAway))
                .overlay(Capsule().strokeBorder(selected ? Night.tracker : .clear, lineWidth: UIMetrics.calendarSelectedBorder))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .padding(UIMetrics.calendarRaisedRing)
        .accessibilityLabel(text.spoken)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("calendar.awayBackdrop.label")
    }

    private var stripes: some View {
        Canvas { ctx, size in
            var path = Path()
            var x = -size.height
            while x < size.width {
                path.move(to: CGPoint(x: x, y: size.height))
                path.addLine(to: CGPoint(x: x + size.height, y: 0))
                x += UIMetrics.calendarStripeSpacing
            }
            ctx.stroke(path, with: .color(Night.calendarAway.opacity(UIMetrics.calendarStripeOpacity)), lineWidth: UIMetrics.calendarStripeWidth)
        }
    }
}
