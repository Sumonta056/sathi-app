import SathiCore
import SwiftUI

struct CalendarEventCard: View {
    let placed: CalendarPlacedBlock
    let math: CalendarGridMath
    let context: CalendarBlockContext
    var width: CGFloat = .infinity

    private var block: CalendarBlock { placed.block }
    private var top: CGFloat { math.y(for: placed.displaySpan.start) }
    private var height: CGFloat { math.height(placed.displaySpan) }

    private var titleHeight: CGFloat {
        placed.shownChildren.first.map { math.y(for: $0.displaySpan.start) - top } ?? height
    }

    var body: some View {
        let look = CalendarBlockLook.of(block.style, categories: context.categories)
        ZStack(alignment: .topLeading) {
            Button { context.press(block, top) } label: {
                face(look)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(spoken)
            .accessibilityIdentifier("calendar.event.face")
            ForEach(placed.shownChildren, id: \.block.id) { child in
                let childTop = math.y(for: child.displaySpan.start)
                CalendarActivityBlock(
                    placed: child, height: math.height(child.displaySpan), context: context, y: childTop,
                    width: width - 2 * UIMetrics.calendarChildInset
                )
                .padding(.horizontal, UIMetrics.calendarChildInset)
                .offset(y: childTop - top)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: max(height, UIMetrics.calendarBarMinHeight), alignment: .topLeading)
        .modifier(CalendarBlockChrome(look: look, radius: UIMetrics.calendarEventRadius, selected: false, raised: placed.isRaised))
        .onHover { context.hover(placed, $0) }
    }

    private var inside: Int {
        placed.children.flatMap(\.block.rows).count
    }

    private var spoken: String {
        let text = context.text(block).spoken
        return block.copies > 1 ? text + ", " + Copywriter.calendarCopiesSpoken(block.copies) : text
    }

    @ViewBuilder private func face(_ look: CalendarBlockLook) -> some View {
        if CalendarBlockFit.showsText(height: titleHeight) {
            VStack(alignment: .leading, spacing: UIMetrics.calendarBlockSpacing) {
                HStack(alignment: .firstTextBaseline, spacing: UIMetrics.calendarCopiesGap) {
                    Image(systemName: "calendar")
                        .font(Typography.tracker(UIMetrics.calendarIconFont, .semibold))
                        .foregroundStyle(look.stroke ?? look.text)
                        .accessibilityHidden(true)
                    Text(verbatim: block.title)
                        .font(Typography.tracker(UIMetrics.calendarBlockFont, .bold))
                        .lineLimit(CalendarBlockFit.titleLines(height: titleHeight))
                    Spacer(minLength: 0)
                    if block.copies > 1 { CalendarBlockBadge(text: Copywriter.calendarCopies(block.copies)) }
                    if placed.hiddenCount > 0 { CalendarBlockBadge(text: Copywriter.calendarHiddenCount(placed.hiddenCount)) }
                    if !placed.kidsShown, !placed.children.isEmpty { CalendarInsideChip(count: inside, width: width) }
                }
                if CalendarBlockFit.showsTimeRange(height: titleHeight) {
                    Text(verbatim: context.text(block).time)
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
