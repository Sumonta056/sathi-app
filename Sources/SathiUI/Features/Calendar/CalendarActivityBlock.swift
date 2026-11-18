import SathiCore
import SwiftUI

struct CalendarActivityBlock: View {
    let placed: CalendarPlacedBlock
    let height: CGFloat
    let context: CalendarBlockContext
    var y: CGFloat = 0
    var width: CGFloat = .infinity

    private var block: CalendarBlock { placed.block }

    var body: some View {
        let look = CalendarBlockLook.of(block.style, categories: context.categories)
        let selected = context.isSelected(block)
        Button { context.press(block, y) } label: {
            face(look)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .frame(height: max(height, UIMetrics.calendarBarMinHeight), alignment: .topLeading)
                .modifier(CalendarBlockChrome(look: look, radius: UIMetrics.calendarBlockRadius, selected: selected, raised: placed.isRaised))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { context.hover(placed, $0) }
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityLabel(context.text(block).spoken)
    }

    private var detail: String? {
        guard let detail = block.group?.detail, CalendarBlockFit.showsTimeRange(height: height) else { return nil }
        return detail
    }

    private var lines: Int {
        let below = detail == nil ? 0 : UIMetrics.calendarTimeLineHeight
        return CalendarBlockFit.activityTitleLines(height: height, width: width, below: below)
    }

    private var showsTime: Bool {
        detail == nil || height + UIMetrics.calendarFitTolerance >= UIMetrics.calendarGroupDetailMinHeight
    }

    @ViewBuilder private func face(_ look: CalendarBlockLook) -> some View {
        if !CalendarBlockFit.showsText(height: height) {
            Color.clear
        } else if CalendarBlockFit.showsTimeRange(height: height) {
            VStack(alignment: .leading, spacing: UIMetrics.calendarBlockSpacing) {
                title(lines: lines)
                if let detail { small(detail) }
                if showsTime { small(context.text(block).time) }
            }
            .foregroundStyle(look.text)
            .padding(UIMetrics.calendarBlockPadding)
        } else {
            HStack(spacing: UIMetrics.calendarCopiesGap) {
                title(lines: 1)
                Spacer(minLength: 0)
                small(Copywriter.calendarHours(block.interval.duration)).fixedSize()
            }
            .foregroundStyle(look.text)
            .padding(UIMetrics.calendarBlockPadding)
        }
    }

    private func title(lines: Int) -> some View {
        CalendarActivityTitle(placed: placed, categories: context.categories, lines: lines, width: width)
    }

    private func small(_ text: String) -> some View {
        Text(verbatim: text)
            .font(Typography.tracker(UIMetrics.calendarBlockTimeFont, .medium))
            .opacity(UIMetrics.calendarTimeOpacity)
            .lineLimit(1)
    }
}
