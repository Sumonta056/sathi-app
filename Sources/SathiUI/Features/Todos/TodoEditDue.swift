import SathiCore
import SwiftUI

struct TodoEditDue: View {
    @Binding var form: TodoEditForm
    let today: Date
    let hadDue: Bool

    var body: some View {
        HStack(spacing: UIMetrics.todoChipSpacing) {
            Text(verbatim: Copywriter.todoDue)
                .font(Typography.tracker(UIMetrics.todoRowMetaFont, .medium))
                .foregroundStyle(Night.label)
                .frame(width: UIMetrics.todoEditLabelWidth, alignment: .leading)
            BuddySwitch(isOn: hasDate, accent: Night.todo, label: Copywriter.todoDue)
                .accessibilityIdentifier("todos.edit.hasDate")
            if form.hasDate {
                DatePicker("", selection: $form.date, displayedComponents: .date)
                    .labelsHidden()
                    .fixedSize()
                if form.minutes != nil {
                    TimeMenu(minutes: minutes, accent: Night.todo, active: true)
                    chip(Copywriter.todoNoTime, "todos.edit.noTime") { form.minutes = nil }
                } else {
                    chip(Copywriter.todoAddTime, "todos.edit.addTime") { form.minutes = Limits.todoDefaultDueMinutes }
                }
            }
        }
    }

    private var hasDate: Binding<Bool> {
        Binding(
            get: { form.hasDate },
            set: { on in
                if on, !hadDue, !form.hasDate { form.date = today }
                form.hasDate = on
            }
        )
    }

    private var minutes: Binding<Int> {
        Binding(get: { form.minutes ?? Limits.todoDefaultDueMinutes }, set: { form.minutes = $0 })
    }

    private func chip(_ title: String, _ id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(verbatim: title).accessibilityIdentifier(id)
        }
        .buttonStyle(GhostButton(accent: Night.chipText))
    }
}
