import SathiCore
import SwiftUI

struct CalendarDayColumn: View {
    let placed: [CalendarPlacedBlock]
    let texts: [String: CalendarBlockText]
    let math: CalendarGridMath
    let now: Date?
    let categories: [ActivityCategory]
    let calendar: Calendar

    var body: some View {
        GeometryReader { geo in
            let width = max(0, geo.size.width - 2 * UIMetrics.calendarColumnInset)
            ZStack(alignment: .topLeading) {
                ForEach(placed, id: \.block.id) { p in
                    let lane = width / CGFloat(max(1, p.lanes))
                    CalendarBlockView(
                        block: p.block, text: texts[p.block.id] ?? CalendarBlockText(time: "", spoken: p.block.title),
                        height: math.height(p.span), categories: categories
                    )
                    .frame(width: max(0, lane - UIMetrics.calendarLaneGap))
                    .offset(x: UIMetrics.calendarColumnInset + lane * CGFloat(p.lane), y: math.y(for: p.span.start))
                }
                if let now, math.holds(now) {
                    CalendarNowLine(now: now, calendar: calendar)
                        .frame(width: geo.size.width)
                        .position(x: geo.size.width / 2, y: math.y(for: now))
                }
            }
        }
        .frame(height: math.totalHeight)
    }
}
