import SathiCore
import SwiftUI

struct DayOffCalendar: View {
    let habit: HabitID
    let accent: Color
    @Binding var offset: Int
    let onPick: () -> Void
    @EnvironmentObject var e: Engine

    var body: some View {
        let month = e.dayOffMonth(habit, offset: offset)
        VStack(spacing: UIMetrics.calendarSpacing) {
            header(month)
            weekdayRow
            ForEach(Array(month.weeks.enumerated()), id: \.offset) { _, week in
                HStack(spacing: UIMetrics.calendarSpacing) {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, cell in
                        slot(cell)
                    }
                }
            }
        }
        .padding(UIMetrics.timePickerPadding)
        .background(Night.card)
        .environment(\.colorScheme, .dark)
    }

    private func header(_ month: DayOffMonth) -> some View {
        HStack {
            arrow("chevron.left", label: "Previous month", enabled: month.canGoBack) { offset -= 1 }
            Spacer()
            Text(verbatim: Self.title(month.firstDay))
                .font(Typography.chip)
                .foregroundStyle(Night.text)
            Spacer()
            arrow("chevron.right", label: "Next month", enabled: month.canGoForward) { offset += 1 }
        }
    }

    private func arrow(_ symbol: String, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: UIMetrics.dayOffRemoveIconSize, weight: .heavy))
                .foregroundStyle(enabled ? accent : Night.faint)
                .frame(width: UIMetrics.dayChipSize, height: UIMetrics.dayChipSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(Text(verbatim: label))
    }

    private var weekdayRow: some View {
        HStack(spacing: UIMetrics.calendarSpacing) {
            ForEach(Array(Weekday.allCases.enumerated()), id: \.offset) { _, weekday in
                Text(verbatim: weekday.shortLabel)
                    .font(Typography.hint)
                    .foregroundStyle(Night.label)
                    .frame(width: UIMetrics.dayChipSize)
            }
        }
    }

    @ViewBuilder
    private func slot(_ cell: DayOffCell?) -> some View {
        if let cell {
            DayOffCellButton(cell: cell, accent: accent) {
                e.addDayOff(habit, key: cell.key)
                onPick()
            }
        } else {
            Color.clear.frame(width: UIMetrics.dayChipSize, height: UIMetrics.dayChipSize)
        }
    }

    static func title(_ firstDay: DayKey) -> String {
        formatter.string(from: firstDay.start(in: utc))
    }

    private static let utc = Calendar.gregorian(in: .gmt)

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = utc
        f.timeZone = .gmt
        f.setLocalizedDateFormatFromTemplate("MMMMyyyy")
        return f
    }()
}
