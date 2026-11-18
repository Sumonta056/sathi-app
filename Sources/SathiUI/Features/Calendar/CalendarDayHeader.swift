import SathiCore
import SwiftUI

struct CalendarDayHeader: View {
    let blocks: [CalendarLaidBlock]
    let actualWidth: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            label(Copywriter.calendarDayActual(Self.tracked(blocks)))
                .frame(width: actualWidth, alignment: .leading)
            Color.clear.frame(width: UIMetrics.calendarDayLinkGutter)
            label(Copywriter.calendarDayPlan(Self.events(blocks)))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: UIMetrics.calendarSplitLabelHeight)
    }

    static func tracked(_ blocks: [CalendarLaidBlock]) -> TimeInterval {
        all(blocks).filter(isTracked).reduce(0) { $0 + $1.span.duration }
    }

    static func events(_ blocks: [CalendarLaidBlock]) -> Int {
        all(blocks).filter { b in
            if case .event = b.block.source { return !b.block.isAllDay }
            return false
        }.count
    }

    private static func all(_ blocks: [CalendarLaidBlock]) -> [CalendarLaidBlock] {
        blocks.flatMap { [$0] + $0.hidden }
    }

    private static func isTracked(_ b: CalendarLaidBlock) -> Bool {
        guard b.block.style != .away, case let .activity(a, _) = b.block.source else { return false }
        return a.kind != .away
    }

    private func label(_ text: String) -> some View {
        Text(verbatim: text)
            .font(Typography.tracker(UIMetrics.calendarDaySplitHeaderFont, .bold))
            .foregroundStyle(Night.muted)
            .lineLimit(1)
    }
}
