import SathiCore
import SwiftUI

struct TodoEditDue: View {
    @Binding var hasDate: Bool
    @Binding var date: Date
    @Binding var minutes: Int?

    var body: some View {
        HStack(spacing: UIMetrics.todoChipSpacing) {
            Text(verbatim: Copywriter.todoDue)
                .font(Typography.tracker(UIMetrics.todoRowMetaFont, .medium))
                .foregroundStyle(Night.label)
                .frame(width: UIMetrics.todoEditLabelWidth, alignment: .leading)
            BuddySwitch(isOn: $hasDate, accent: Night.todo, label: Copywriter.todoDue)
                .accessibilityIdentifier("todos.edit.hasDate")
            if hasDate {
                DatePicker("", selection: $date, displayedComponents: .date)
                    .labelsHidden()
                    .fixedSize()
                if minutes != nil {
                    TimeMenu(minutes: time, accent: Night.todo, active: true)
                    chip(Copywriter.todoNoTime, "todos.edit.noTime") { minutes = nil }
                } else {
                    chip(Copywriter.todoAddTime, "todos.edit.addTime") { minutes = Limits.todoDefaultDueMinutes }
                }
            }
        }
    }

    private var time: Binding<Int> {
        Binding(get: { minutes ?? Limits.todoDefaultDueMinutes }, set: { minutes = $0 })
    }

    private func chip(_ title: String, _ id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(verbatim: title).accessibilityIdentifier(id)
        }
        .buttonStyle(GhostButton(accent: Night.chipText))
    }
}
