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

    static func parts(_ text: String) -> (String, String) {
        guard let r = text.range(of: Copywriter.calendarDayHeaderSeparator) else { return (text, "") }
        return (String(text[..<r.lowerBound]), String(text[r.lowerBound...]))
    }

    private func label(_ text: String) -> some View {
        let (word, rest) = Self.parts(text)
        return (
            Text(verbatim: word).font(Typography.tracker(UIMetrics.calendarDaySplitHeaderFont, .heavy)).foregroundColor(Night.text)
                + Text(verbatim: rest).font(Typography.tracker(UIMetrics.calendarDaySplitHeaderFont, .semibold)).foregroundColor(Night.muted)
        )
        .lineLimit(1)
    }
}
