import SathiCore
import SwiftUI

struct TodoTick: View {
    let isDone: Bool
    let canEdit: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .strokeBorder(isDone ? Night.todo : Night.todoTick, lineWidth: UIMetrics.todoTickBorder)
                    .background(Circle().fill(isDone ? Night.todo : .clear))
                if isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: UIMetrics.todoTickMark, weight: .heavy))
                        .foregroundStyle(Night.onAccent)
                }
            }
            .frame(width: UIMetrics.todoTick, height: UIMetrics.todoTick)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!canEdit)
        .accessibilityLabel(Text(verbatim: isDone ? Copywriter.todoMarkNotDone : Copywriter.todoMarkDone))
    }
}
