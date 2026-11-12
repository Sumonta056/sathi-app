import SathiCore
import SwiftUI

struct DaysOffCard: View {
    private let make: @MainActor (Engine) -> DaysOffSource
    @EnvironmentObject var e: Engine

    static let emptyText = "No days off planned."

    init(habit: HabitID) {
        make = { DaysOffSource.habit(habit, $0) }
    }

    init(source make: @escaping @MainActor (Engine) -> DaysOffSource) {
        self.make = make
    }

    static func hint(_ id: HabitID) -> String {
        "\(id.buddy) stays quiet on these days. They never break your streak."
    }

    var body: some View {
        let source = make(e)
        let upcoming = source.upcoming()
        SettingsSection(Copywriter.daysOffTitle) {
            SettingsCard {
                SettingRow(label: Copywriter.daysOffAdd, hint: source.hint, showsDivider: false) {
                    DayOffPicker(make: make, accent: source.accent)
                }
                if upcoming.isEmpty {
                    emptyLine
                } else {
                    ForEach(upcoming, id: \.self) { key in
                        DaysOffRow(key: key, accent: source.accent) { source.remove(key) }
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
