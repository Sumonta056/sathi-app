import SathiCore
import SwiftUI

struct TodoBoardColumnPicker: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: "rectangle.split.3x1")
                .font(.system(size: UIMetrics.todoPickerIcon, weight: .medium))
                .foregroundStyle(Night.muted)
                .padding(UIMetrics.todoPickerIconPadding)
                .accessibilityHidden(true)
            ForEach(TodoBoardColumnChoice.allCases, id: \.self) { segment($0) }
        }
        .padding(UIMetrics.todoSwitchPadding)
        .background(shape(UIMetrics.todoSwitchRadius).fill(Night.card))
        .overlay(shape(UIMetrics.todoSwitchRadius).strokeBorder(Night.border, lineWidth: UIMetrics.todoBorder))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Copywriter.todoBoardColumnsLabel)
        .accessibilityIdentifier("todos.board.columns")
        .help(Copywriter.todoBoardColumnsLabel)
    }

    private func segment(_ choice: TodoBoardColumnChoice) -> some View {
        let on = e.data.prefs.todos.boardColumns == choice
        return Button { e.setTodoBoardColumns(choice) } label: {
            Text(verbatim: Copywriter.todoBoardColumns(choice))
                .font(Typography.tracker(UIMetrics.todoSwitchFont, .semibold))
                .foregroundStyle(on ? Night.text : Night.muted)
                .padding(UIMetrics.todoPickerItemPadding)
                .background(shape(UIMetrics.todoSwitchItemRadius).fill(on ? Night.navSelected : Color.clear))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func shape(_ radius: CGFloat) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }
}
