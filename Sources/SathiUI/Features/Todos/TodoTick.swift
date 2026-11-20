import SathiCore
import SwiftUI

struct TodoTick: View {
    let isDone: Bool
    let canEdit: Bool
    var size: CGFloat = UIMetrics.todoTick
    var color: Color = Night.todo
    var idleColor: Color = Night.todoTick
    var reduceMotion = false
    var phase: TodoFinishPhase?
    let action: () -> Void

    static func showsPop(phase: TodoFinishPhase?, reduceMotion: Bool) -> Bool {
        phase == .checked && !reduceMotion
    }

    static func showsRing(phase: TodoFinishPhase?, reduceMotion: Bool) -> Bool {
        showsPop(phase: phase, reduceMotion: reduceMotion)
    }

    private var shownDone: Bool { isDone || phase != nil }

    var body: some View {
        Button(action: action) {
            face
                .frame(width: size, height: size)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!canEdit)
        .accessibilityLabel(Text(verbatim: shownDone ? Copywriter.todoMarkNotDone : Copywriter.todoMarkDone))
    }

    @ViewBuilder private var face: some View {
        if Self.showsPop(phase: phase, reduceMotion: reduceMotion) {
            TodoTickBurst(size: size, color: color, idleColor: idleColor)
        } else {
            ZStack {
                Circle()
                    .strokeBorder(shownDone ? color : idleColor, lineWidth: UIMetrics.todoTickBorder)
                    .background(Circle().fill(shownDone ? color : .clear))
                if shownDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: size * UIMetrics.todoTickMark / UIMetrics.todoTick, weight: .heavy))
                        .foregroundStyle(Night.onAccent)
                }
            }
            .animation(reduceMotion ? nil : .easeOut(duration: UIMetrics.todoFillSeconds), value: shownDone)
        }
    }
}
