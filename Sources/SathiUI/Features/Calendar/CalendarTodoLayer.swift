import SathiCore
import SwiftUI

struct CalendarTodoLayer: View {
    let placed: [CalendarPlacedBlock]
    let math: CalendarGridMath
    let width: CGFloat

    static func holds(_ p: CalendarPlacedBlock) -> Bool {
        if case .todo = p.block.source { return true }
        return false
    }

    var body: some View {
        ForEach(placed.filter(Self.holds), id: \.block.id) { p in
            let y = math.y(for: p.block.interval.start)
            let pill = width * UIMetrics.calendarTodoPillWidthShare
            CalendarTodoDueLine(block: p.block)
                .frame(width: width)
                .offset(x: UIMetrics.calendarColumnInset, y: y - UIMetrics.calendarTodoLineWidth / 2)
            CalendarTodoChip(block: p.block, isPill: true)
                .frame(width: pill)
                .offset(x: UIMetrics.calendarColumnInset + width - pill, y: max(0, y - UIMetrics.calendarTodoPillHeight / 2))
        }
    }
}
