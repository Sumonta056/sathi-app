import SathiCore
import SwiftUI

struct TodoBoardCard: View {
    let section: TodoListSection
    @Binding var editingID: String?
    @Binding var reorder: TodoReorder
    let onAdd: (() -> Void)?
    @State private var frames = TodoRowFrames()
    @EnvironmentObject var e: Engine

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            ForEach(section.todos, id: \.id) { todo in
                Rectangle().fill(Night.divider).frame(height: UIMetrics.dividerHeight)
                row(todo).padding(.horizontal, UIMetrics.todoBoardRowInset)
            }
        }
        .coordinateSpace(name: TodoReorderRow.space)
        .onPreferenceChange(TodoRowFramesKey.self) { frames.all = $0 }
        .background(shape.fill(Night.card))
        .overlay(shape.strokeBorder(Night.border, lineWidth: UIMetrics.todoBorder))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("todos.board.card." + section.list.id)
    }

    private var color: Color { Night.todoList(section.list.colorHex) }

    private var header: some View {
        HStack(spacing: UIMetrics.todoBoardHeadSpacing) {
            Circle()
                .fill(color)
                .frame(width: UIMetrics.todoBoardDot, height: UIMetrics.todoBoardDot)
                .accessibilityIdentifier("todos.board.dot." + section.list.id)
            Text(verbatim: section.list.name)
                .font(Typography.tracker(UIMetrics.todoBoardTitleFont, .bold))
                .foregroundStyle(Night.text)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(verbatim: "\(section.todos.count)")
                .font(Typography.tracker(UIMetrics.todoBoardCountFont, .bold))
                .foregroundStyle(Night.chipText)
                .padding(UIMetrics.todoBoardCountPadding)
                .background(Capsule().fill(Night.divider))
            if let onAdd { addButton(onAdd) }
        }
        .padding(UIMetrics.todoBoardHeadPadding)
        .frame(minHeight: UIMetrics.todoBoardAdd + UIMetrics.todoBoardHeadPadding.top + UIMetrics.todoBoardHeadPadding.bottom)
        .background(TodoBoardTop(radius: UIMetrics.todoBoardRadius).fill(color.opacity(UIMetrics.todoBoardTint)))
    }

    private func addButton(_ onAdd: @escaping () -> Void) -> some View {
        Button(action: onAdd) {
            Image(systemName: "plus")
                .font(.system(size: UIMetrics.todoBoardAddIcon, weight: .semibold))
                .foregroundStyle(Night.muted)
                .frame(width: UIMetrics.todoBoardAdd, height: UIMetrics.todoBoardAdd)
                .contentShape(RoundedRectangle(cornerRadius: UIMetrics.todoBoardAddRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .help(Copywriter.todoBoardAdd(list: section.list.name))
        .accessibilityLabel(Copywriter.todoBoardAdd(list: section.list.name))
        .accessibilityIdentifier("todos.board.add." + section.list.id)
    }

    @ViewBuilder private func row(_ todo: Todo) -> some View {
        if editingID == todo.id {
            TodoEditCard(todo: todo) { editingID = nil }
        } else {
            TodoRow(todo: todo, canEdit: section.list.canEdit) { editingID = todo.id }
                .todoReorder(todo.id, peers: section.todos.map(\.id), frames: frames, state: $reorder) { e.moveTodo($0, before: $1) }
        }
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.todoBoardRadius, style: .continuous)
    }
}

struct TodoBoardTop: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let r = min(radius, rect.height, rect.width / 2)
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        p.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.minY), tangent2End: CGPoint(x: rect.minX + r, y: rect.minY), radius: r)
        p.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        p.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.minY), tangent2End: CGPoint(x: rect.maxX, y: rect.minY + r), radius: r)
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
