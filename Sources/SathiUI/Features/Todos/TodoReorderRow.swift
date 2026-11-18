import SwiftUI

struct TodoReorderRow: ViewModifier {
    static let space = "todo.items"

    let id: String
    let peers: [String]
    let frames: TodoRowFrames
    @Binding var state: TodoReorder
    let move: (String, String?) -> Void

    func body(content: Content) -> some View {
        let lifted = state.id == id
        content
            .background(GeometryReader { g in
                Color.clear.preference(key: TodoRowFramesKey.self, value: [id: g.frame(in: .named(Self.space))])
            })
            .background {
                if lifted {
                    RoundedRectangle(cornerRadius: UIMetrics.todoListRadius, style: .continuous)
                        .fill(Night.card)
                        .overlay(RoundedRectangle(cornerRadius: UIMetrics.todoListRadius, style: .continuous).strokeBorder(
                            Night.border,
                            lineWidth: UIMetrics.todoBorder
                        ))
                }
            }
            .offset(y: state.offset(id))
            .zIndex(lifted ? 1 : 0)
            .animation(lifted ? nil : .easeOut(duration: UIMetrics.todoReorderAnimation), value: state.to)
            .gesture(drag)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: UIMetrics.todoDragStart, coordinateSpace: .named(Self.space))
            .onChanged { v in
                if state.id == nil { state.start(id: id, peers: peers, frames: frames.all) }
                guard state.id == id else { return }
                state.update(dy: v.translation.height)
            }
            .onEnded { _ in
                guard state.id == id else { return }
                let before = state.before
                let changed = state.to != state.from
                withAnimation(.easeOut(duration: UIMetrics.todoReorderAnimation)) {
                    if changed { move(id, before) }
                    state = TodoReorder()
                }
            }
    }
}

extension View {
    func todoReorder(
        _ id: String,
        peers: [String],
        frames: TodoRowFrames,
        state: Binding<TodoReorder>,
        move: @escaping (String, String?) -> Void
    ) -> some View {
        modifier(TodoReorderRow(id: id, peers: peers, frames: frames, state: state, move: move))
    }
}
