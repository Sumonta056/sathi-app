import SathiCore
import SwiftUI

struct CalendarBlockView: View {
    let block: CalendarBlock
    let text: CalendarBlockText
    let height: CGFloat
    let categories: [ActivityCategory]

    static func showsText(height: CGFloat) -> Bool { height >= UIMetrics.calendarBlockMinHeight }

    static func showsTimeRange(height: CGFloat) -> Bool { height >= UIMetrics.calendarTimeRangeMinHeight }

    var body: some View {
        let look = CalendarBlockLook.of(block.style, categories: categories)
        let shape = RoundedRectangle(cornerRadius: UIMetrics.calendarBlockRadius, style: .continuous)
        content(look)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .frame(height: max(height, UIMetrics.calendarBarMinHeight), alignment: .topLeading)
            .background(shape.fill(look.fill))
            .overlay(shape.strokeBorder(look.stroke ?? .clear, lineWidth: UIMetrics.cardBorder))
            .clipShape(shape)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(text.spoken)
    }

    @ViewBuilder private func content(_ look: CalendarBlockLook) -> some View {
        if Self.showsText(height: height) {
            VStack(alignment: .leading, spacing: UIMetrics.calendarBlockSpacing) {
                Text(verbatim: block.title)
                    .font(Typography.tracker(UIMetrics.calendarBlockFont, .bold))
                    .lineLimit(1)
                if Self.showsTimeRange(height: height) {
                    Text(verbatim: text.time)
                        .font(Typography.tracker(UIMetrics.calendarBlockTimeFont, .medium))
                        .opacity(UIMetrics.calendarTimeOpacity)
                        .lineLimit(1)
                }
            }
            .foregroundStyle(look.text)
            .padding(UIMetrics.calendarBlockPadding)
        } else {
            Color.clear
        }
    }
}
