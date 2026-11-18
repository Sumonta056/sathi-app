import SathiCore
import SwiftUI

struct CalendarWeekBlock: View {
    let laid: CalendarLaidBlock
    let size: CGSize
    let narrow: Bool
    let calendar: Calendar
    let categories: [ActivityCategory]
    var doneColor: Color?

    static func titleLines(height: Double, narrow: Bool) -> Int {
        if narrow { return height >= UIMetrics.calendarWeekBlockMinHeight ? UIMetrics.calendarWeekNarrowLinesMax : 1 }
        let fit = Int(((height - UIMetrics.calendarWeekTimeRoom) / UIMetrics.calendarWeekLineHeight).rounded(.down))
        return min(UIMetrics.calendarWeekTitleLinesMax, max(1, fit))
    }

    private var block: CalendarBlock { laid.block }
    private var isEvent: Bool { if case .event = block.source { true } else { false } }
    private var isAway: Bool { block.style == .away }
    private var look: CalendarBlockLook { CalendarBlockLook.of(block.style, categories: categories) }
    private var lines: Int { Self.titleLines(height: Double(size.height), narrow: narrow) }

    private var edge: Color {
        if isAway { return Color(hex: NightHex.trackerAway) }
        if case let .activity(category) = block.style { return Color(hex: ActivityColors.hex(category, in: categories)) }
        return look.stroke ?? look.text
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.calendarWeekBlockRadius, style: .continuous)
        ZStack(alignment: .topLeading) {
            if isAway { CalendarStripes() }
            if narrow { narrowFace } else { wideFace }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .background(isEvent || isAway ? Night.card : look.fill)
        .overlay(alignment: .leading) { edge.frame(width: UIMetrics.calendarWeekBlockEdge) }
        .overlay(alignment: .bottomTrailing) { dot }
        .clipShape(shape)
        .overlay(outline(shape))
        .background(ring(shape))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Copywriter.calendarBlockSpoken(block.title, laid.rounded.start, laid.rounded.end, calendar: calendar))
    }

    private var wideFace: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: UIMetrics.calendarCopiesGap) {
                icon
                title(UIMetrics.calendarWeekTitleFont)
                Spacer(minLength: 0)
                badges
            }
            Text(verbatim: Copywriter.calendarBlockTime(laid.rounded, calendar: calendar))
                .font(Typography.tracker(UIMetrics.calendarWeekTimeFont, .medium))
                .foregroundStyle(Night.chipText)
                .lineLimit(1)
        }
        .padding(UIMetrics.calendarWeekBlockPadding)
    }

    private var narrowFace: some View {
        HStack(alignment: .firstTextBaseline, spacing: UIMetrics.calendarCopiesGap) {
            icon
            Text(verbatim: Copywriter.calendarStartClock(laid.rounded.start, calendar: calendar))
                .font(Typography.tracker(UIMetrics.calendarWeekTimeFont, .semibold))
                .foregroundStyle(Night.chipText)
                .fixedSize()
            title(UIMetrics.calendarWeekNarrowFont)
            Spacer(minLength: 0)
            badges
        }
        .padding(UIMetrics.calendarWeekNarrowPadding)
    }

    @ViewBuilder private var icon: some View {
        if isEvent {
            Image(systemName: "calendar")
                .font(Typography.tracker(UIMetrics.calendarIconFont, .semibold))
                .foregroundStyle(edge)
                .accessibilityHidden(true)
        }
    }

    private func title(_ size: CGFloat) -> some View {
        Text(verbatim: block.title)
            .font(Typography.tracker(size, .bold))
            .foregroundStyle(isAway ? Night.muted : Night.text)
            .lineLimit(lines)
    }

    @ViewBuilder private var badges: some View {
        if block.copies > 1 { CalendarBlockBadge(text: Copywriter.calendarCopies(block.copies)) }
        if !laid.hidden.isEmpty { CalendarBlockBadge(text: Copywriter.calendarHiddenCount(laid.hidden.count)) }
    }

    @ViewBuilder private var dot: some View {
        if laid.doneDuring != nil {
            Circle()
                .fill(doneColor ?? Night.faint)
                .frame(width: UIMetrics.calendarWeekDoneDot, height: UIMetrics.calendarWeekDoneDot)
                .padding(UIMetrics.calendarWeekGap)
                .accessibilityIdentifier("calendar.week.doneDot")
        }
    }

    @ViewBuilder private func outline(_ shape: RoundedRectangle) -> some View {
        if isEvent {
            shape.strokeBorder(edge.opacity(UIMetrics.calendarWeekEventStrokeOpacity), lineWidth: UIMetrics.cardBorder)
        } else if isAway {
            shape.strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder)
        }
    }

    @ViewBuilder private func ring(_ shape: RoundedRectangle) -> some View {
        if laid.isRaised {
            shape.fill(Night.bg)
                .padding(-UIMetrics.calendarRaisedRing)
                .accessibilityIdentifier("calendar.block.ring")
        }
    }
}
