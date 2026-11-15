import SathiCore
import SwiftUI

struct CalendarTodoPopover: View {
    let todoID: String
    let onClose: () -> Void
    @EnvironmentObject var e: Engine

    var body: some View {
        Group {
            if let todo = e.todoSnapshot.todos.first(where: { $0.id == todoID }) {
                TodoEditCard(todo: todo, onClose: onClose)
            }
        }
        .padding(UIMetrics.calendarPopoverPadding)
        .frame(width: UIMetrics.calendarPopoverWidth, alignment: .leading)
        .background(Night.card)
    }
}
