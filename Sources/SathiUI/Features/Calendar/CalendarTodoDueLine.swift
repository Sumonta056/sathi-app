import SathiCore
import SwiftUI

struct CalendarTodoDueLine: View {
    let block: CalendarBlock

    private var color: Color { CalendarBlockLook.of(block.style, categories: []).stroke ?? Night.faint }

    private var todoID: String {
        if case let .todo(id) = block.source { return id }
        return block.id
    }

    var body: some View {
        DueLinePath()
            .stroke(color, style: StrokeStyle(lineWidth: UIMetrics.calendarTodoLineWidth, dash: UIMetrics.calendarTodoLineDash))
            .frame(height: UIMetrics.calendarTodoLineWidth)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .accessibilityIdentifier("calendar.todo.line." + todoID)
    }
}

private struct DueLinePath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}
