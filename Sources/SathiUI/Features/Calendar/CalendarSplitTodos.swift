import SathiCore
import SwiftUI

struct CalendarSplitTodos: View {
    let todos: [CalendarLaidBlock]
    let halves: CalendarSplitHalves
    var hover: (CalendarLaidBlock, CGRect, Bool) -> Void = { _, _, _ in }

    var body: some View {
        ForEach(todos) { laid in
            let line = CalendarSplitGeometry.dueLine(top: laid.top, halves: halves)
            let pill = CalendarSplitGeometry.todoRect(laid, halves: halves)
            CalendarTodoDueLine(block: laid.block)
                .frame(width: line.width)
                .offset(x: line.minX, y: line.minY)
            CalendarTodoChip(block: laid.block, isPill: true)
                .onHover { hover(laid, pill, $0) }
                .frame(width: pill.width)
                .offset(x: pill.minX, y: pill.minY)
        }
    }
}
