import SathiCore
import SwiftUI

struct CalendarDayLink: Identifiable {
    let id: String
    let color: Color
    let points: [CGPoint]
}

struct CalendarDayLinks: View {
    let blocks: [CalendarLaidBlock]
    let halves: CalendarSplitHalves
    let colors: [String: Color]

    var body: some View {
        let links = Self.links(blocks: blocks, halves: halves, colors: colors)
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

    static func links(blocks: [CalendarLaidBlock], halves: CalendarSplitHalves, colors: [String: Color]) -> [CalendarDayLink] {
        let events = Dictionary(blocks.filter { $0.half == .plan }.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        return blocks.compactMap { a in
            guard a.half == .actual, let id = a.doneDuring, let e = events[id] else { return nil }
            return CalendarDayLink(
                id: a.id, color: colors[id] ?? fallback(e),
                points: points(activity: a, event: e, halves: halves)
            )
        }
    }

    static func points(activity a: CalendarLaidBlock, event e: CalendarLaidBlock, halves: CalendarSplitHalves) -> [CGPoint] {
        let r = UIMetrics.calendarDayLinkDot / 2
        let from = CalendarSplitGeometry.rect(a, halves: halves)
        let to = CalendarSplitGeometry.rect(e, halves: halves)
        let ya = min(max(from.midY, from.minY + r), from.maxY - r)
        let mid = (halves.actualX + halves.actualWidth + halves.planX) / 2
        return [CGPoint(x: from.maxX, y: ya), CGPoint(x: mid, y: ya), CGPoint(x: mid, y: to.midY), CGPoint(x: to.minX, y: to.midY)]
    }

    private static func fallback(_ e: CalendarLaidBlock) -> Color {
        if case let .event(hex) = e.block.style { return Color(hex: hex) }
        return Night.trackerEvent
    }
}
