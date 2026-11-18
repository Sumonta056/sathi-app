import SathiCore
import SwiftUI

struct CalendarBlockView: View {
    let block: CalendarBlock
    let text: CalendarBlockText
    let height: CGFloat
    let categories: [ActivityCategory]
    var selected = false
    var raised = false

    static func border(selected: Bool) -> CGFloat {
        selected ? UIMetrics.calendarSelectedBorder : UIMetrics.cardBorder
    }

    static func showsText(height: CGFloat) -> Bool { height >= UIMetrics.calendarBlockMinHeight }

    static func showsTimeRange(height: CGFloat) -> Bool { height >= UIMetrics.calendarTimeRangeMinHeight }

    var body: some View {
        let look = CalendarBlockLook.of(block.style, categories: categories)
        let shape = RoundedRectangle(cornerRadius: UIMetrics.calendarBlockRadius, style: .continuous)
        content(look)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .frame(height: max(height, UIMetrics.calendarBarMinHeight), alignment: .topLeading)
            .background(shape.fill(look.fill))
            .background(shape.fill(raised ? Night.card : .clear))
            .overlay(shape.strokeBorder(selected ? Night.tracker : (look.stroke ?? .clear), lineWidth: Self.border(selected: selected)))
            .clipShape(shape)
            .background(shape.fill(raised ? Night.card : .clear).padding(-UIMetrics.calendarRaisedRing))
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(selected ? .isSelected : [])
            .accessibilityLabel(spoken)
    }

    private var spoken: String {
        block.copies > 1 ? text.spoken + ", " + Copywriter.calendarCopiesSpoken(block.copies) : text.spoken
    }

    private var titleRow: some View {
        HStack(spacing: UIMetrics.calendarCopiesGap) {
            Text(verbatim: block.title)
                .font(Typography.tracker(UIMetrics.calendarBlockFont, .bold))
                .lineLimit(1)
            if block.copies > 1 {
                Text(verbatim: Copywriter.calendarCopies(block.copies))
                    .font(Typography.tracker(UIMetrics.calendarCopiesFont, .bold))
                    .foregroundStyle(Night.onAccent)
                    .padding(UIMetrics.calendarCopiesPadding)
                    .background(Capsule().fill(Night.text))
                    .fixedSize()
            }
        }
    }

    @ViewBuilder private func content(_ look: CalendarBlockLook) -> some View {
        if Self.showsText(height: height) {
            VStack(alignment: .leading, spacing: UIMetrics.calendarBlockSpacing) {
                titleRow
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
