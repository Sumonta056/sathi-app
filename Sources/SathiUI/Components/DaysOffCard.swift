import SathiCore
import SwiftUI

struct DaysOffCard: View {
    let habit: HabitID
    @EnvironmentObject var e: Engine

    static let emptyText = "No days off planned."

    static func hint(_ id: HabitID) -> String {
        "\(id.buddy) stays quiet on these days. They never break your streak."
    }

    var body: some View {
        let engine = e
        let accent = Night.accent(habit)
        let upcoming = engine.upcomingDaysOff(habit)
        SettingsSection("Days off") {
            SettingsCard {
                SettingRow(label: "Add a day off", hint: Self.hint(habit), showsDivider: false) {
                    DayOffPicker(habit: habit, accent: accent)
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
