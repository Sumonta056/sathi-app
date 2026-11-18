import SathiCore
import SwiftUI

struct TodoRow: View {
    let todo: Todo
    let canEdit: Bool
    let onSelect: () -> Void
    @EnvironmentObject var e: Engine

    init(todo: Todo, canEdit: Bool, onSelect: @escaping () -> Void) {
        self.todo = todo
        self.canEdit = canEdit
        self.onSelect = onSelect
    }

    var body: some View {
        HStack(alignment: .center, spacing: UIMetrics.todoRowSpacing) {
            TodoTick(isDone: todo.isDone, canEdit: canEdit) {
                let engine = e
                let id = todo.id
                let done = !todo.isDone
                Task { await engine.setTodoDone(id, done) }
            }
            .overlay { if !canEdit { Color.clear.contentShape(Rectangle()).onTapGesture {} } }
            Text(Self.attributedTitle(TodoTitlePart.parts(of: todo.title), linked: !todo.isDone))
                .font(Typography.tracker(UIMetrics.todoRowTitleFont, .medium))
                .foregroundStyle(todo.isDone ? Night.muted : Night.text)
                .strikethrough(todo.isDone)
                .tint(Night.todoLink)
                .environment(\.openURL, Self.openAction(e))
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("todos.row.title.\(todo.id)")
            TodoRowMeta(todo: todo)
        }
        .padding(UIMetrics.todoRowPadding)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: Text(verbatim: Copywriter.todoEdit), onSelect)
        .accessibilityIdentifier("todos.row.\(todo.id)")
        .overlay(alignment: .bottom) {
            Rectangle().fill(Night.todoRowLine).frame(height: UIMetrics.dividerHeight)
        }
    }

    static func attributedTitle(_ parts: [TodoTitlePart], linked: Bool = true) -> AttributedString {
        parts.reduce(into: AttributedString()) { out, part in
            switch part {
            case let .text(s):
                out += AttributedString(s)
            case let .link(label, url):
                var piece = AttributedString(label)
                guard linked else { return out += piece }
                piece.link = url
                piece.underlineStyle = .single
                out += piece
            }
        }
    }

    static func openAction(_ e: Engine) -> OpenURLAction {
        OpenURLAction { url in
            e.openTodoLink(url)
            return .handled
        }
    }
}
