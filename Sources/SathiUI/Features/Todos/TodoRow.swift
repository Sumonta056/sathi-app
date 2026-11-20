import SathiCore
import SwiftUI

struct TodoRow: View {
    let todo: Todo
    let canEdit: Bool
    let metaBelow: Bool
    let onSelect: () -> Void
    @EnvironmentObject var e: Engine
    @EnvironmentObject var finishing: TodoFinishing
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(todo: Todo, canEdit: Bool, metaBelow: Bool = false, onSelect: @escaping () -> Void) {
        self.todo = todo
        self.canEdit = canEdit
        self.metaBelow = metaBelow
        self.onSelect = onSelect
    }

    var body: some View {
        HStack(alignment: .center, spacing: UIMetrics.todoRowSpacing) {
            TodoTick(isDone: todo.isDone, canEdit: canEdit, reduceMotion: reduceMotion, phase: phase, action: tick)
                .overlay { if !canEdit { Color.clear.contentShape(Rectangle()).onTapGesture {} } }
            if metaBelow {
                VStack(alignment: .leading, spacing: UIMetrics.todoBoardMetaGap) {
                    title
                    if todo.repeats || todo.due != nil { TodoRowMeta(todo: todo, below: true) }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                title
                TodoRowMeta(todo: todo)
            }
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
        .modifier(TodoFold(phase: phase, reduceMotion: reduceMotion))
        .onDisappear { finishing.flush(todo.id) }
    }

    private var title: some View {
        Text(Self.attributedTitle(TodoTitlePart.parts(of: todo.title), linked: !todo.isDone))
            .font(Typography.tracker(UIMetrics.todoRowTitleFont, .medium))
            .foregroundStyle(todo.isDone || phase != nil ? Night.muted : Night.text)
            .strikethrough(todo.isDone)
            .overlay { if phase != nil && !todo.isDone { TodoStrike(reduceMotion: reduceMotion) } }
            .tint(Night.todoLink)
            .environment(\.openURL, Self.openAction(e))
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifier("todos.row.title.\(todo.id)")
    }

    private var phase: TodoFinishPhase? { finishing.phase(todo.id) }

    private func tick() {
        guard !todo.isDone else {
            let engine = e
            let id = todo.id
            Task { await engine.setTodoDone(id, false) }
            return
        }
        finishing.tick(todo.id)
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
