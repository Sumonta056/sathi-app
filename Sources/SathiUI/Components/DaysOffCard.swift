import SathiCore
import SwiftUI

struct DaysOffCard: View {
    let habit: HabitID
    @EnvironmentObject var e: Engine
    @State private var picked: Date?

    static let emptyText = "No days off planned."

    static func hint(_ id: HabitID) -> String {
        "\(id.buddy) stays quiet on these days. They never break your streak."
    }

    var body: some View {
        let engine = e
        let range = engine.dayOffRange
        let accent = Night.accent(habit)
        let upcoming = engine.upcomingDaysOff(habit)
        SettingsSection("Days off") {
            SettingsCard {
                SettingRow(label: "Add a day off", hint: Self.hint(habit), showsDivider: false) {
                    HStack(spacing: UIMetrics.chipSpacing) {
                        DatePicker("Day off", selection: date(in: range), in: range, displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .environment(\.timeZone, engine.timeZone)
                            .environment(\.calendar, Calendar.gregorian(in: engine.timeZone))
                        Button { add(engine) } label: {
                            Text(verbatim: "Add")
                        }
                        .buttonStyle(GhostButton(accent: accent, height: UIMetrics.chipHeight))
                    }
                }
                if upcoming.isEmpty {
                    emptyLine
                } else {
                    ForEach(upcoming, id: \.self) { key in
                        DaysOffRow(key: key, accent: accent) { engine.removeDayOff(habit, key) }
                    }
                }
            }
        }
    }

    private func add(_ engine: Engine) {
        let r = engine.dayOffRange
        engine.addDayOff(habit, (picked ?? r.lowerBound).clamped(to: r))
    }

    private func date(in range: ClosedRange<Date>) -> Binding<Date> {
        Binding(get: { (picked ?? range.lowerBound).clamped(to: range) }, set: { picked = $0 })
    }

    private var emptyLine: some View {
        Text(verbatim: Self.emptyText)
            .font(Typography.hint)
            .foregroundStyle(Night.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(UIMetrics.rowPadding)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Night.divider)
                    .frame(height: UIMetrics.dividerHeight)
            }
    }
}

private extension Date {
    func clamped(to range: ClosedRange<Date>) -> Date {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
