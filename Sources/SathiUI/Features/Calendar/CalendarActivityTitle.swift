import SathiCore
import SwiftUI

struct CalendarActivityTitle: View {
    let placed: CalendarPlacedBlock
    let categories: [ActivityCategory]
    var lines = 1
    var width: CGFloat = .infinity

    private var block: CalendarBlock { placed.block }

    var body: some View {
        HStack(alignment: lines > 1 ? .top : .center, spacing: UIMetrics.calendarCopiesGap) {
            if block.group != nil { icon("square.stack") }
            Text(verbatim: block.title)
                .font(Typography.tracker(UIMetrics.calendarBlockFont, .bold))
                .lineLimit(lines)
            if case .joined = block.style { icon("link") }
            if let badge = block.group?.badge { CalendarBlockBadge(text: badge) }
            if placed.hiddenCount > 0 { CalendarBlockBadge(text: Copywriter.calendarHiddenCount(placed.hiddenCount)) }
            if showsDots {
                Spacer(minLength: 0)
                dots
            }
        }
    }

    private var showsDots: Bool {
        (block.group?.categories.count ?? 0) > 1 && !CalendarNarrowLanes.isNarrow(width)
    }

    private var dots: some View {
        HStack(spacing: UIMetrics.calendarGroupDotGap) {
            ForEach(Array((block.group?.categories ?? []).enumerated()), id: \.offset) { _, category in
                Circle()
                    .fill(Color(hex: ActivityColors.hex(category, in: categories)))
                    .frame(width: UIMetrics.calendarGroupDotSize, height: UIMetrics.calendarGroupDotSize)
                    .accessibilityIdentifier("calendar.group.dot")
            }
        }
        .accessibilityHidden(true)
    }

    private func icon(_ name: String) -> some View {
        Image(systemName: name)
            .font(Typography.tracker(UIMetrics.calendarIconFont, .semibold))
            .accessibilityHidden(true)
    }
}
