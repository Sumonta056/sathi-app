import SathiCore
import SwiftUI

struct TodoItemsHeader: View {
    let page: TodoPageModel
    let accent: Color
    @Binding var showCompleted: Bool
    @EnvironmentObject var e: Engine

    var body: some View {
        HStack(alignment: .center, spacing: UIMetrics.todoHeaderSpacing) {
            listsButton
            HStack(alignment: .firstTextBaseline, spacing: UIMetrics.todoHeaderSpacing) {
                Text(verbatim: page.title)
                    .font(Typography.tracker(UIMetrics.todoTitleFont, .heavy))
                    .foregroundStyle(accent)
                    .layoutPriority(1)
                Text(verbatim: Copywriter.todoPageCount(open: page.open.count, lists: isAll ? page.sections.count : nil))
                    .font(Typography.tracker(UIMetrics.todoHeaderCountFont, .semibold))
                    .foregroundStyle(Night.muted)
            }
            Spacer(minLength: 0)
            if isBoard { TodoBoardColumnPicker() }
            if isAll { viewSwitch }
            if !isBoard, !page.completed.isEmpty { toggle(page.completed.count) }
        }
        .lineLimit(1)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("todos.header")
    }

    private var isAll: Bool { page.selection == .smart(.all) }

    private var isBoard: Bool { isAll && e.data.prefs.todos.allView == .board }

    private var listsButton: some View {
        let hidden = e.data.prefs.todos.sideHidden
        let label = hidden ? Copywriter.todoShowLists : Copywriter.todoHideLists
        return Button { e.setTodoSideHidden(!hidden) } label: {
            Image(systemName: "sidebar.squares.left")
                .font(.system(size: UIMetrics.todoListsIcon, weight: .medium))
                .foregroundStyle(hidden ? Night.muted : Night.text)
                .frame(width: UIMetrics.todoListsButton, height: UIMetrics.todoListsButton)
                .background(listsShape.fill(hidden ? Color.clear : Night.navSelected))
                .overlay(listsShape.strokeBorder(Night.border, lineWidth: UIMetrics.todoBorder))
                .contentShape(listsShape)
        }
        .buttonStyle(.plain)
        .keyboardShortcut("s", modifiers: [.control, .command])
        .help(label)
        .accessibilityLabel(label)
        .accessibilityIdentifier("todos.lists.toggle")
    }

    private var listsShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.todoListsRadius, style: .continuous)
    }

    private var viewSwitch: some View {
        HStack(spacing: 0) {
            segment(.list, Copywriter.todoViewList)
            segment(.board, Copywriter.todoViewBoard)
        }
        .padding(UIMetrics.todoSwitchPadding)
        .background(switchShape(UIMetrics.todoSwitchRadius).fill(Night.card))
        .overlay(switchShape(UIMetrics.todoSwitchRadius).strokeBorder(Night.border, lineWidth: UIMetrics.todoBorder))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Copywriter.todoViewLabel)
        .accessibilityIdentifier("todos.view.switch")
    }

    private func segment(_ view: TodoAllView, _ title: String) -> some View {
        let on = e.data.prefs.todos.allView == view
        return Button { e.setTodoAllView(view) } label: {
            Text(verbatim: title)
                .font(Typography.tracker(UIMetrics.todoSwitchFont, .semibold))
                .foregroundStyle(on ? Night.text : Night.muted)
                .padding(UIMetrics.todoSwitchItemPadding)
                .background(switchShape(UIMetrics.todoSwitchItemRadius).fill(on ? Night.navSelected : Color.clear))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func switchShape(_ radius: CGFloat) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
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
}
