import SathiCore
import SwiftUI

struct TodoItemsColumn: View {
    let selection: TodoSelection
    @State private var showCompleted: Bool
    @State private var editingID: String?
    @State private var reorder = TodoReorder()
    @State private var frames = TodoRowFrames()
    @Environment(\.mainLayout) private var layout
    @EnvironmentObject var e: Engine

    init(selection: TodoSelection, showCompleted: Bool = false) {
        self.selection = selection
        _showCompleted = State(initialValue: showCompleted)
    }

    var body: some View {
        let page = e.todoPage(selection)
        let rows = showCompleted ? page.open + page.completed : page.open
        VStack(alignment: .leading, spacing: UIMetrics.todoItemsSpacing) {
            header(page)
            if let target = page.targetListID {
                TodoAddField(listID: target, due: page.defaultDue).id(target)
            }
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    if rows.isEmpty {
                        Text(verbatim: Copywriter.todoEmptyList)
                            .font(Typography.hint)
                            .foregroundStyle(Night.faint)
                            .padding(UIMetrics.todoRowPadding)
                    }
                    if page.sections.isEmpty {
                        ForEach(rows, id: \.id) { item($0, peers: page.open) }
                    } else {
                        ForEach(page.sections, id: \.list.id) { section in
                            TodoSectionHeader(list: section.list, count: section.todos.count)
                            ForEach(section.todos, id: \.id) { item($0, peers: section.todos) }
                        }
                    }
                }
                .coordinateSpace(name: TodoReorderRow.space)
                .onPreferenceChange(TodoRowFramesKey.self) { frames.all = $0 }
            }
        }
        .padding(Self.padding(layout))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder private func item(_ todo: Todo, peers: [Todo]) -> some View {
        if editingID == todo.id {
            TodoEditCard(todo: todo) { editingID = nil }
        } else if Self.canDrag(selection), !todo.isDone {
            TodoRow(todo: todo, canEdit: canEdit(todo)) { editingID = todo.id }
                .todoReorder(todo.id, peers: peers.map(\.id), frames: frames, state: $reorder) { e.moveTodo($0, before: $1) }
        } else {
            TodoRow(todo: todo, canEdit: canEdit(todo)) { editingID = todo.id }
        }
    }

    static func canDrag(_ selection: TodoSelection) -> Bool {
        switch selection {
        case .list, .smart(.all): true
        case .smart: false
        }
    }

    private func header(_ page: TodoPageModel) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: UIMetrics.todoHeaderSpacing) {
            Text(verbatim: page.title)
                .font(Typography.tracker(UIMetrics.todoTitleFont, .heavy))
                .foregroundStyle(accent)
                .layoutPriority(1)
            Text(verbatim: Copywriter.todoPageCount(open: page.open.count, lists: selection == .smart(.all) ? page.sections.count : nil))
                .font(Typography.tracker(UIMetrics.todoHeaderCountFont, .semibold))
                .foregroundStyle(Night.muted)
            Spacer(minLength: 0)
            if !page.completed.isEmpty { toggle(page.completed.count) }
        }
        .lineLimit(1)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("todos.header")
    }

    private func toggle(_ count: Int) -> some View {
        Button { showCompleted.toggle() } label: {
            Text(verbatim: showCompleted ? Copywriter.todoHideCompleted : Copywriter.todoCompletedToggle(count))
                .font(Typography.tracker(UIMetrics.todoToggleFont, .medium))
                .foregroundStyle(Night.muted)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var accent: Color {
        switch selection {
        case .smart(.all): Night.text
        case let .smart(list): Night.todoTile(list).dot
        case .list: Night.text
        }
    }

    static func padding(_ layout: MainLayout) -> EdgeInsets {
        layout.isNarrow ? UIMetrics.todoItemsPaddingNarrow : UIMetrics.todoItemsPadding
    }

    private func canEdit(_ todo: Todo) -> Bool {
        e.todoSnapshot.lists.first { $0.id == todo.listID }?.canEdit ?? false
    }
}
