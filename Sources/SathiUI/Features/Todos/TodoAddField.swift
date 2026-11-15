import SathiCore
import SwiftUI

struct TodoAddField: View {
    let listID: String
    let due: TodoDue?
    @State private var title: String
    @State private var pick: TodoDue?
    @State private var picking = false
    @EnvironmentObject var e: Engine

    init(listID: String, title: String = "", due: TodoDue? = nil) {
        self.listID = listID
        self.due = due
        _title = State(initialValue: title)
        _pick = State(initialValue: due)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.todoChipSpacing) {
            HStack(spacing: UIMetrics.todoRowSpacing) {
                Image(systemName: "plus")
                    .font(.system(size: UIMetrics.todoAddIcon, weight: .bold))
                    .foregroundStyle(Night.spark)
                TextField(Copywriter.todoNewPlaceholder, text: $title)
                    .textFieldStyle(.plain)
                    .font(Typography.tracker(UIMetrics.todoFieldFont, .medium))
                    .foregroundStyle(Night.text)
                    .onSubmit(add)
                    .accessibilityIdentifier("todos.add.field")
                Button(action: add) {
                    Text(verbatim: Copywriter.todoAdd).accessibilityIdentifier("todos.add.button")
                }
                .buttonStyle(GhostButton(accent: Night.todo))
                .disabled(isBlank)
            }
            dueChip
                .padding(.leading, UIMetrics.todoAddIcon + UIMetrics.todoRowSpacing)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("todos.add.stack")
        .padding(UIMetrics.todoAddPadding)
        .background(shape.fill(Night.todoField))
        .overlay(shape.strokeBorder(Night.border, lineWidth: UIMetrics.todoBorder))
    }

    private var dueChip: some View {
        Button { picking = true } label: {
            Text(verbatim: pick.map { Copywriter.todoDueText($0, now: e.now, calendar: e.calendar) } ?? Copywriter.todoNoDate)
                .accessibilityIdentifier("todos.add.due")
        }
        .buttonStyle(GhostButton(accent: pick == nil ? Night.chipText : Night.todo))
        .popover(isPresented: $picking, arrowEdge: .bottom) {
            TodoEditDue(hasDate: hasDate, date: date, minutes: minutes)
                .environmentObject(e)
                .padding(UIMetrics.todoEditPadding)
                .frame(width: UIMetrics.todoDuePopoverWidth, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .background(Night.card)
        }
    }

    private var today: Date { e.calendar.startOfDay(for: e.now) }

    private var hasDate: Binding<Bool> {
        Binding(get: { pick != nil }, set: { pick = $0 ? TodoDue(date: today, hasTime: false) : nil })
    }

    private var date: Binding<Date> {
        Binding(get: { pick?.date ?? today }, set: { d in
            pick = TodoDue.make(hasDate: true, date: d, minutes: pick?.minutes(calendar: e.calendar), calendar: e.calendar)
        })
    }

    private var minutes: Binding<Int?> {
        Binding(get: { pick?.minutes(calendar: e.calendar) }, set: { m in
            pick = TodoDue.make(hasDate: true, date: pick?.date ?? today, minutes: m, calendar: e.calendar)
        })
    }

    private var isBlank: Bool { title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    private func add() {
        guard !isBlank else { return }
        let engine = e
        let sent = title
        let draft = TodoDraft(listID: listID, title: sent, notes: "", due: pick)
        Task {
            let r = await engine.addTodo(draft)
            title = TodoAddRule.titleAfterAdd(current: title, sent: sent, result: r)
        }
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.todoAddRadius, style: .continuous)
    }
}
