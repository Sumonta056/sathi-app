import SathiCore
import SwiftUI

struct TodoBoard: View {
    static let space = "todo.board"

    let sections: [TodoListSection]
    @Binding var editingID: String?
    @Binding var reorder: TodoReorder
    let onAdd: (String) -> Void
    @State private var width: Double?
    @State private var slot: TodoBoardSlot?
    @State private var frames = TodoBoardFrames()
    @EnvironmentObject var e: Engine

    var body: some View {
        TodoBoardLayout(columns: columns, gap: UIMetrics.todoBoardGap, fixed: fixed) {
            ForEach(items, id: \.key) { item in
                switch item {
                case let .column(index): marker(index)
                case let .card(section): card(section)
                case .slot: TodoBoardDropSlot().layoutValue(key: TodoBoardPartKey.self, value: .slot)
                }
            }
        }
        .coordinateSpace(name: Self.space)
        .onPreferenceChange(TodoBoardCardFramesKey.self) { frames.cards = $0 }
        .onPreferenceChange(TodoBoardColumnFramesKey.self) { frames.columns = $0 }
        .onChange(of: canDrag) { if !$0 { cancel() } }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .opacity(width == nil ? 0 : 1)
        .background(GeometryReader { g in
            Color.clear.preference(key: TodoBoardWidthKey.self, value: Double(g.size.width))
        })
        .onPreferenceChange(TodoBoardWidthKey.self) { width = $0 }
        .padding(.top, UIMetrics.todoBoardTopPadding)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("todos.board")
    }

    private var choice: TodoBoardColumnChoice { e.data.prefs.todos.boardColumns }

    private var columns: Int {
        guard let count = choice.count else {
            return TodoBoardColumns.count(width: width, min: UIMetrics.todoBoardMinWidth, gap: UIMetrics.todoBoardGap)
        }
        guard let width else { return count }
        return TodoBoardColumnLayout.fit(
            width: width, count: count, min: Limits.todoBoardMinFixedColumn, gap: Double(UIMetrics.todoBoardGap)
        )
    }

    private var fixed: TodoBoardFixed? {
        guard let count = choice.count else { return nil }
        return TodoBoardFixed(saved: e.data.prefs.todos.boardLayouts[String(count)] ?? [], count: count, slot: slot)
    }

    private var items: [TodoBoardItem] {
        let markers = fixed == nil ? [] : (0 ..< columns).map(TodoBoardItem.column)
        return markers + sections.map(TodoBoardItem.card) + (slot == nil ? [] : [.slot])
    }

    private func card(_ section: TodoListSection) -> some View {
        TodoBoardCard(
            section: section,
            editingID: $editingID,
            reorder: $reorder,
            onAdd: section.list.canEdit ? { onAdd(section.list.id) } : nil,
            drag: drag(section.list.id)
        )
        .background { if canDrag { frameReader(section.list.id) } }
        .layoutValue(key: TodoBoardKey.self, value: section.list.id)
        .zIndex(slot?.id == section.list.id ? 2 : holdsDrag(section) ? 1 : 0)
    }

    private var canDrag: Bool { TodoBoardDropTarget.canDrag(count: choice.count, fit: columns) }

    private func drag(_ id: String) -> TodoBoardDrag? {
        guard canDrag else { return nil }
        return TodoBoardDrag(lifted: slot?.id == id, changed: { moved(id, $0) }, ended: { drop(id) })
    }

    private func moved(_ id: String, _ point: CGPoint) {
        frames.start(id)
        let t = TodoBoardDropTarget.target(point: point, columns: frames.snapshot, excluding: id)
        let next = TodoBoardSlot(id: id, column: t.column, before: t.before)
        guard next != slot else { return }
        withAnimation(.easeOut(duration: UIMetrics.todoReorderAnimation)) { slot = next }
    }

    private func drop(_ id: String) {
        if let slot, slot.id == id, let count = choice.count {
            e.moveTodoBoard(id, column: slot.column, before: slot.before, shown: frames.shown(count: count))
        }
        cancel()
    }

    private func cancel() {
        slot = nil
        frames.reset()
    }

    private func marker(_ index: Int) -> some View {
        Color.clear
            .background(GeometryReader { g in
                Color.clear.preference(key: TodoBoardColumnFramesKey.self, value: [index: g.frame(in: .named(Self.space))])
            })
            .allowsHitTesting(false)
            .accessibilityIdentifier("todos.board.column.\(index)")
            .layoutValue(key: TodoBoardPartKey.self, value: .column(index))
    }

    private func frameReader(_ id: String) -> some View {
        GeometryReader { g in
            Color.clear.preference(key: TodoBoardCardFramesKey.self, value: [id: g.frame(in: .named(Self.space))])
        }
    }

    private func holdsDrag(_ section: TodoListSection) -> Bool {
        guard let id = reorder.id else { return false }
        return section.todos.contains { $0.id == id }
    }
}

struct TodoBoardWidthKey: PreferenceKey {
    static let defaultValue: Double? = nil

    static func reduce(value: inout Double?, nextValue: () -> Double?) {
        value = nextValue() ?? value
    }
}
