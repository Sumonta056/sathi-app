import SathiCore
import SwiftUI

struct DaySummaryTodosLine: View {
    let todos: DaySummaryTodos

    var body: some View {
        HStack(spacing: UIMetrics.cornerRowSpacing) {
            Image(systemName: "checkmark.circle")
                .foregroundStyle(Night.promptTodo)
                .accessibilityHidden(true)
            Text(verbatim: Copywriter.todoDaySummaryLine(done: todos.done, left: todos.left))
                .font(Typography.hint)
                .foregroundStyle(Night.text)
            Spacer(minLength: 0)
        }
    }
}
