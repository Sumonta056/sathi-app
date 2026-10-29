import SathiCore
import SwiftUI

struct QuickAddForm: View {
    @EnvironmentObject var e: Engine
    @State private var text: String
    @State private var chip: Int?
    @State private var time: Date?
    let onClose: () -> Void

    static let defaultChip = Limits.quickChips[1]

    init(text: String = "", chip: Int? = QuickAddForm.defaultChip, time: Date? = nil, onClose: @escaping () -> Void) {
        _text = State(initialValue: text)
        _chip = State(initialValue: chip)
        _time = State(initialValue: time)
        self.onClose = onClose
    }

    static func when(chip: Int?, time: Date, calendar: Calendar) -> QuickTime {
        if let chip { return .inMinutes(chip) }
        return .at(minutes: DayClock(calendar: calendar).minutesOfDay(time))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.quickFormSpacing) {
            HStack(spacing: UIMetrics.chipSpacing) {
                Image(systemName: "bell")
                    .font(.system(size: UIMetrics.quickIconSize, weight: .heavy))
                    .foregroundStyle(Night.quick)
                Text(verbatim: "New quick reminder")
                    .font(Typography.cardTitle)
                    .foregroundStyle(Night.text)
            }
            textField
            if e.quickReminders.count >= Limits.quickMax {
                Text(verbatim: "You have \(Limits.quickMax) quick reminders. Delete one to add more.")
                    .font(Typography.hint)
                    .foregroundStyle(Night.muted)
            } else {
                whenSection
            }
            buttons
        }
        .quickCardStyle()
    }

    private var calendar: Calendar { Calendar.gregorian(in: e.timeZone) }

    private var shown: Date { time ?? e.quickDate(.inMinutes(chip ?? Self.defaultChip)) }

    private var quickTime: QuickTime { Self.when(chip: chip, time: shown, calendar: calendar) }

    private var isBlank: Bool { QuickText.clean(text).isEmpty }

    private var timeBinding: Binding<Date> {
        Binding(get: { shown }, set: { time = $0; chip = nil })
    }

    private var textField: some View {
        VStack(alignment: .leading, spacing: UIMetrics.quickFieldSpacing) {
            SectionLabel("Remind me to")
            LazyTextField(placeholder: "Remind me to", text: $text, startsEditing: true, onSubmit: add)
                .modifier(QuickTextLimit(text: $text, limit: Limits.quickTextMax))
                .frame(height: UIMetrics.quickFieldHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous)
                        .strokeBorder(Night.quick, lineWidth: UIMetrics.quickFieldBorder)
                )
            Text(verbatim: "\(text.count) / \(Limits.quickTextMax)")
                .font(Typography.pill)
                .foregroundStyle(Night.faint)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var whenSection: some View {
        VStack(alignment: .leading, spacing: UIMetrics.chipSpacing) {
            SectionLabel("When")
            QuickChips(selected: chip) { minutes in
                chip = minutes
                time = nil
            }
            HStack(spacing: UIMetrics.quickTimeSpacing) {
                Text(verbatim: "or at")
                    .font(Typography.hint)
                    .foregroundStyle(Night.muted)
                DatePicker("or at", selection: timeBinding, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(.field)
                    .environment(\.timeZone, e.timeZone)
                    .environment(\.calendar, calendar)
                Text(verbatim: e.quickPreview(quickTime))
                    .font(Typography.hint)
                    .foregroundStyle(Night.quick)
            }
            Text(verbatim: "A time that has passed today goes to tomorrow.")
                .font(Typography.pill)
                .foregroundStyle(Night.faint)
        }
    }

    private var buttons: some View {
        HStack(spacing: UIMetrics.chipSpacing) {
            Spacer(minLength: 0)
            Button(action: onClose) { Text(verbatim: "Cancel") }
                .buttonStyle(GhostButton(accent: Night.chipText, height: UIMetrics.quickButtonHeight, border: Night.border))
            if e.quickReminders.count < Limits.quickMax {
                Button(action: add) { Text(verbatim: "Add reminder") }
                    .buttonStyle(AccentButton(accent: Night.quick, height: UIMetrics.quickButtonHeight))
                    .disabled(isBlank)
            }
        }
    }

    private func add() {
        guard !isBlank else { return }
        if case .added = e.addQuick(text: text, when: quickTime) { onClose() }
    }
}
