import SathiCore
import SwiftUI

struct CalendarDayLink: Identifiable {
    let id: String
    let color: Color
    let points: [CGPoint]
}

struct CalendarDayLinks: View {
    let blocks: [CalendarLaidBlock]
    let actualWidth: CGFloat
    let planX: CGFloat
    let colors: [String: Color]

    var body: some View {
        let links = Self.links(blocks: blocks, actualWidth: actualWidth, planX: planX, colors: colors)
        ZStack(alignment: .topLeading) {
            ForEach(links) { link in
                Path { $0.addLines(link.points) }
                    .stroke(
                        link.color.opacity(UIMetrics.calendarDayLinkOpacity),
                        style: StrokeStyle(lineWidth: UIMetrics.calendarDayLinkWidth, lineCap: .round, lineJoin: .round)
                    )
                if let dot = link.points.first {
                    Circle()
                        .fill(link.color)
                        .overlay(Circle().strokeBorder(Night.bg, lineWidth: UIMetrics.calendarDayLinkDotBorder))
                        .frame(width: UIMetrics.calendarDayLinkDot, height: UIMetrics.calendarDayLinkDot)
                        .position(dot)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .accessibilityIdentifier("calendar.day.links")
    }

    static func links(blocks: [CalendarLaidBlock], actualWidth: CGFloat, planX: CGFloat, colors: [String: Color]) -> [CalendarDayLink] {
        let events = Dictionary(blocks.filter { $0.half == .plan }.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        return blocks.compactMap { a in
            guard a.half == .actual, let id = a.doneDuring, let e = events[id] else { return nil }
            return CalendarDayLink(
                id: a.id, color: colors[id] ?? fallback(e),
                points: points(activity: a, event: e, actualWidth: actualWidth, planX: planX)
            )
        }
    }

    static func points(activity a: CalendarLaidBlock, event e: CalendarLaidBlock, actualWidth: CGFloat, planX: CGFloat) -> [CGPoint] {
        let r = UIMetrics.calendarDayLinkDot / 2
        let right = actualWidth * CGFloat(a.lane + 1) / CGFloat(max(1, a.lanes))
        let ya = min(max((a.top + a.bottom) / 2, a.top + r), a.bottom - r)
        let share = UIMetrics.calendarActualShare
        let planWidth = actualWidth * (1 - share) / share
        let left = planX + planWidth * CGFloat(e.lane) / CGFloat(max(1, e.lanes)) + CGFloat(e.depth) * UIMetrics.calendarCascadeIndent
        let ye = (e.top + e.bottom) / 2
        let mid = (actualWidth + planX) / 2
        return [CGPoint(x: right, y: ya), CGPoint(x: mid, y: ya), CGPoint(x: mid, y: ye), CGPoint(x: left, y: ye)]
    }

    private static func fallback(_ e: CalendarLaidBlock) -> Color {
        if case let .event(hex) = e.block.style { return Color(hex: hex) }
        return Night.trackerEvent
    }
}
