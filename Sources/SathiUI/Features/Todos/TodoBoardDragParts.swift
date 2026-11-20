import SathiCore
import SwiftUI

struct TodoBoardDrag {
    let lifted: Bool
    let changed: (CGPoint) -> Void
    let ended: () -> Void
}

final class TodoBoardFrames {
    var cards: [String: CGRect] = [:]
    var columns: [Int: CGRect] = [:]
    var id: String?
    var snapshot: [TodoBoardDropColumn] = []

    func start(_ id: String) {
        guard self.id != id else { return }
        self.id = id
        snapshot = TodoBoardDropTarget.columns(frames: columns, cards: cards)
    }

    func shown(count: Int) -> [[String]] {
        let ids = snapshot.map { $0.cards.map(\.id) }
        return ids + Array(repeating: [], count: max(0, count - ids.count))
    }

    func reset() {
        id = nil
        snapshot = []
    }
}

struct TodoBoardCardFramesKey: PreferenceKey {
    static let defaultValue: [String: CGRect] = [:]

    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

struct TodoBoardColumnFramesKey: PreferenceKey {
    static let defaultValue: [Int: CGRect] = [:]

    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

struct TodoBoardHeaderDrag: ViewModifier {
    let id: String
    let drag: TodoBoardDrag?
    @Binding var lift: CGSize

    func body(content: Content) -> some View {
        if let drag {
            content
                .contentShape(Rectangle())
                .gesture(gesture(drag))
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("todos.board.drag." + id)
        } else {
            content
        }
    }

    private func gesture(_ drag: TodoBoardDrag) -> some Gesture {
        DragGesture(minimumDistance: UIMetrics.todoDragStart, coordinateSpace: .named(TodoBoard.space))
            .onChanged { v in
                lift = v.translation
                drag.changed(v.location)
            }
            .onEnded { _ in
                withAnimation(.easeOut(duration: UIMetrics.todoReorderAnimation)) {
                    lift = .zero
                    drag.ended()
                }
            }
    }
}

struct TodoBoardDropSlot: View {
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.todoBoardRadius, style: .continuous)
        shape
            .fill(Night.water.opacity(UIMetrics.todoBoardSlotFill))
            .overlay(shape.strokeBorder(
                Night.water,
                style: StrokeStyle(lineWidth: UIMetrics.todoBoardSlotBorder, dash: [UIMetrics.todoBoardSlotDash])
            ))
            .overlay(
                Text(verbatim: Copywriter.todoBoardDropHere)
                    .font(Typography.tracker(UIMetrics.todoBoardSlotFont, .semibold))
                    .foregroundStyle(Night.water)
            )
            .allowsHitTesting(false)
            .accessibilityIdentifier("todos.board.slot")
    }
}

enum TodoBoardItem {
    case column(Int)
    case card(TodoListSection)
    case slot

    var key: String {
        switch self {
        case let .column(index): "column.\(index)"
        case let .card(section): "card." + section.list.id
        case .slot: "slot"
        }
    }
}
