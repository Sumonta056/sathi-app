import SathiCore
import SwiftUI

struct CalendarWeekBlock: View {
    let laid: CalendarLaidBlock
    let size: CGSize
    let narrow: Bool
    let calendar: Calendar
    let categories: [ActivityCategory]
    var doneColor: Color?

    static func titleLines(height: Double) -> Int {
        let fit = Int(((height - UIMetrics.calendarWeekTimeRoom) / UIMetrics.calendarWeekLineHeight).rounded(.down))
        return min(UIMetrics.calendarWeekTitleLinesMax, max(1, fit))
    }

    private var block: CalendarBlock { laid.block }
    private var isEvent: Bool { if case .event = block.source { true } else { false } }
    private var isAway: Bool { block.style == .away }
    private var look: CalendarBlockLook { CalendarBlockLook.of(block.style, categories: categories) }
    private var edge: Color { Self.edge(block.style, categories: categories) }
    private var titleColor: Color { isAway ? Night.muted : Night.text }

    static func edge(_ style: CalendarBlockStyle, categories: [ActivityCategory]) -> Color {
        switch style {
        case .away: Color(hex: NightHex.trackerAway)
        case let .activity(category), let .joined(category): Color(hex: ActivityColors.hex(category, in: categories))
        case let .event(hex), let .todo(hex): Color(hex: hex)
        }
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.calendarWeekBlockRadius, style: .continuous)
        ZStack(alignment: .topLeading) {
            if isAway { CalendarStripes() }
            if narrow {
                CalendarWeekNarrowText(laid: laid, size: size, calendar: calendar, titleColor: titleColor)
            } else {
                wideFace
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .background(isEvent || isAway ? Night.card : look.fill)
        .overlay(alignment: .leading) { edge.frame(width: UIMetrics.calendarWeekBlockEdge) }
        .overlay(alignment: .topTrailing) { dot }
        .clipShape(shape)
        .overlay(outline(shape))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Copywriter.calendarBlockSpoken(block.title, laid.rounded.start, laid.rounded.end, calendar: calendar))
    }

    private var wideFace: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: UIMetrics.calendarCopiesGap) {
                icon
                CalendarWordTitle(
                    text: block.title, font: Typography.tracker(UIMetrics.calendarWeekTitleFont, .bold), color: titleColor,
                    lines: Self.titleLines(height: Double(size.height))
                )
                Spacer(minLength: 0)
                CalendarBlockBadges(laid: laid)
            }
            Text(verbatim: Copywriter.calendarBlockTime(laid.rounded, calendar: calendar))
                .font(Typography.tracker(UIMetrics.calendarWeekTimeFont, .medium))
                .foregroundStyle(Night.chipText)
                .lineLimit(1)
        }
        .padding(UIMetrics.calendarWeekBlockPadding)
    }

    @ViewBuilder private var icon: some View {
        if isEvent {
            Image(systemName: "calendar")
                .font(Typography.tracker(UIMetrics.calendarIconFont, .semibold))
                .foregroundStyle(edge)
                .accessibilityHidden(true)
        }
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
}
