import SathiCore
import SwiftUI

struct CalendarTodoLayer: View {
    let placed: [CalendarPlacedBlock]
    let math: CalendarGridMath
    let width: CGFloat
    var hover: (CalendarPlacedBlock, Bool) -> Void = { _, _ in }

    static func holds(_ p: CalendarPlacedBlock) -> Bool {
        if case .todo = p.block.source { return true }
        return false
    }

    static func pillRect(_ p: CalendarPlacedBlock, math: CalendarGridMath, width: CGFloat) -> CGRect {
        let y = math.y(for: p.block.interval.start)
        let pill = width * UIMetrics.calendarTodoPillWidthShare
        return CGRect(
            x: UIMetrics.calendarColumnInset + width - pill, y: max(0, y - UIMetrics.calendarTodoPillHeight / 2),
            width: pill, height: UIMetrics.calendarTodoPillHeight
        )
    }

    var body: some View {
        ForEach(placed.filter(Self.holds), id: \.block.id) { p in
            let y = math.y(for: p.block.interval.start)
            let rect = Self.pillRect(p, math: math, width: width)
            CalendarTodoDueLine(block: p.block)
                .frame(width: width)
                .offset(x: UIMetrics.calendarColumnInset, y: y - UIMetrics.calendarTodoLineWidth / 2)
            CalendarTodoChip(block: p.block, isPill: true)
                .onHover { hover(p, $0) }
                .frame(width: rect.width)
                .offset(x: rect.minX, y: rect.minY)
        }
    }
}
