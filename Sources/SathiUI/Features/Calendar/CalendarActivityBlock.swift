import SathiCore
import SwiftUI

struct CalendarActivityBlock: View {
    let placed: CalendarPlacedBlock
    let height: CGFloat
    let context: CalendarBlockContext
    var y: CGFloat = 0

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
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityLabel(context.text(block).spoken)
    }

    @ViewBuilder private func face(_ look: CalendarBlockLook) -> some View {
        if !CalendarBlockFit.showsText(height: height) {
            Color.clear
        } else if CalendarBlockFit.showsTimeRange(height: height) {
            VStack(alignment: .leading, spacing: UIMetrics.calendarBlockSpacing) {
                titleRow
                small(context.text(block).time)
            }
            .foregroundStyle(look.text)
            .padding(UIMetrics.calendarBlockPadding)
        } else {
            HStack(spacing: UIMetrics.calendarCopiesGap) {
                titleRow
                Spacer(minLength: 0)
                small(Copywriter.calendarHours(block.interval.duration)).fixedSize()
            }
            .foregroundStyle(look.text)
            .padding(UIMetrics.calendarBlockPadding)
        }
    }

    private var titleRow: some View {
        HStack(spacing: UIMetrics.calendarCopiesGap) {
            Text(verbatim: block.title)
                .font(Typography.tracker(UIMetrics.calendarBlockFont, .bold))
                .lineLimit(1)
            if case .joined = block.style {
                Image(systemName: "link")
                    .font(Typography.tracker(UIMetrics.calendarIconFont, .semibold))
                    .accessibilityHidden(true)
            }
            if placed.hiddenCount > 0 {
                CalendarBlockBadge(text: Copywriter.calendarHiddenCount(placed.hiddenCount))
            }
        }
    }

    private func small(_ text: String) -> some View {
        Text(verbatim: text)
            .font(Typography.tracker(UIMetrics.calendarBlockTimeFont, .medium))
            .opacity(UIMetrics.calendarTimeOpacity)
            .lineLimit(1)
    }
}
