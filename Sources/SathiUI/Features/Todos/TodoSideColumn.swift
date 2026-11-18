import SathiCore
import SwiftUI

struct TodoSideColumn: View {
    @Binding var selection: TodoSelection
    @State private var creating = false
    @State private var renamingID: String?
    @Environment(\.mainLayout) private var layout
    @EnvironmentObject var e: Engine

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.todoSideSpacing) {
            TodoSmartTiles(selection: $selection)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: UIMetrics.todoListRowGap) {
                    ForEach(Self.groups(e.todoSideLists(selection)), id: \.name) { group in
                        Text(verbatim: group.name.uppercased())
                            .font(Typography.tracker(UIMetrics.todoGroupFont, .bold))
                            .tracking(UIMetrics.todoGroupTracking)
                            .foregroundStyle(Night.label)
                            .padding(UIMetrics.todoGroupPadding)
                        ForEach(group.lists, id: \.id) { row($0) }
                    }
                }
            }
            Spacer(minLength: 0)
            newListButton
        }
        .padding(UIMetrics.todoSidePadding)
        .frame(width: Self.width(layout))
        .frame(maxHeight: .infinity, alignment: .top)
        .overlay(alignment: .trailing) {
            Rectangle().fill(Night.divider).frame(width: UIMetrics.dividerHeight)
        }
    }

    private func row(_ list: TodoList) -> some View {
        TodoListRow(
            list: list,
            count: e.todoCount(.list(list.id)),
            isSelected: selection == .list(list.id),
            onSelect: { selection = .list(list.id) },
            onRename: { renamingID = list.id }
        )
        .popover(isPresented: renaming(list.id), arrowEdge: .trailing) {
            TodoListForm(list: list, name: list.name) { renamingID = nil }
                .environmentObject(e)
        }
    }

    private func renaming(_ id: String) -> Binding<Bool> {
        Binding(get: { renamingID == id }, set: { if !$0 { renamingID = nil } })
    }

    private var newListButton: some View {
        Button { creating = true } label: {
            HStack(spacing: UIMetrics.todoChipSpacing) {
                Image(systemName: "plus")
                Text(verbatim: Copywriter.todoNewList)
            }
            .font(Typography.tracker(UIMetrics.todoListFont, .semibold))
            .foregroundStyle(Night.chipText)
            .padding(UIMetrics.todoNewListPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(
                RoundedRectangle(cornerRadius: UIMetrics.todoAddRadius, style: .continuous)
                    .strokeBorder(Night.fieldBorder, style: StrokeStyle(lineWidth: UIMetrics.todoBorder, dash: [UIMetrics.todoDash]))
            )
            .contentShape(Rectangle())
            .accessibilityIdentifier("todos.list.new")
        }
        .buttonStyle(.plain)
        .popover(isPresented: $creating, arrowEdge: .trailing) {
            TodoListForm { creating = false }
                .environmentObject(e)
        }
    }

    static func width(_ layout: MainLayout) -> CGFloat {
        layout.isNarrow ? UIMetrics.todoSideWidthNarrow : UIMetrics.todoSideWidth
    }

    static func groups(_ lists: [TodoList]) -> [TodoListGroup] {
        TodoRules.sideOrder(lists).reduce(into: []) { out, list in
            if out.last?.name == list.accountName {
                out[out.count - 1].lists.append(list)
            } else {
                out.append(TodoListGroup(name: list.accountName, lists: [list]))
            }
        }
    }
}

struct TodoListGroup {
    let name: String
    var lists: [TodoList]
}
