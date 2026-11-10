import SathiCore
import SwiftUI

struct TrackerDaysOffCard: View {
    @EnvironmentObject var e: Engine
    @State private var isOpen = false
    @State private var offset = 0

    static let hint = "Sathi stays quiet on these days."

    var body: some View {
        let engine = e
        let upcoming = engine.upcomingTrackerDaysOff()
        SettingsSection("Days off") {
            SettingsCard {
                SettingRow(label: "Add a day off", hint: Self.hint, showsDivider: false) { picker }
                if upcoming.isEmpty {
                    Text(verbatim: DaysOffCard.emptyText)
                        .font(Typography.hint)
                        .foregroundStyle(Night.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(UIMetrics.rowPadding)
                        .overlay(alignment: .top) { Rectangle().fill(Night.divider).frame(height: UIMetrics.dividerHeight) }
                } else {
                    ForEach(upcoming, id: \.self) { key in
                        DaysOffRow(key: key, accent: Night.tracker) { engine.removeTrackerDayOff(key) }
                    }
                }
            }
        }
    }

    private var picker: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous)
        return Button { isOpen.toggle() } label: {
            Text(verbatim: "Pick a date")
                .font(Typography.chip)
                .foregroundStyle(Night.text)
                .fixedSize()
                .padding(UIMetrics.timeButtonPadding)
                .background(shape.fill(Night.bg))
                .overlay(shape.strokeBorder(TimeMenu.border(isOpen: isOpen, active: false, accent: Night.tracker), lineWidth: UIMetrics.chipBorder))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .fixedSize()
        .popover(isPresented: $isOpen, arrowEdge: .bottom) { TrackerDayOffCalendar(offset: $offset) }
    }
}

struct TrackerDayOffCalendar: View {
    @Binding var offset: Int
    @EnvironmentObject var e: Engine

    var body: some View {
        let month = e.trackerDayOffMonth(offset: offset)
        VStack(spacing: UIMetrics.calendarSpacing) {
            HStack {
                arrow("chevron.left", "Previous month", month.canGoBack) { offset -= 1 }
                Spacer()
                Text(verbatim: DayOffCalendar.title(month.firstDay)).font(Typography.chip).foregroundStyle(Night.text)
                Spacer()
                arrow("chevron.right", "Next month", month.canGoForward) { offset += 1 }
            }
            HStack(spacing: UIMetrics.calendarSpacing) {
                ForEach(Array(Weekday.allCases.enumerated()), id: \.offset) { _, day in
                    Text(verbatim: day.shortLabel).font(Typography.hint).foregroundStyle(Night.label).frame(width: UIMetrics.dayChipSize)
                }
            }
            ForEach(Array(month.weeks.enumerated()), id: \.offset) { _, week in
                HStack(spacing: UIMetrics.calendarSpacing) {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, cell in slot(cell) }
                }
            }
        }
        .padding(UIMetrics.timePickerPadding)
        .background(Night.card)
        .environment(\.colorScheme, .dark)
    }

    @ViewBuilder private func slot(_ cell: DayOffCell?) -> some View {
        if let cell {
            DayOffCellButton(cell: cell, accent: Night.tracker) { e.addTrackerDayOff(cell.key) }
        } else {
            Color.clear.frame(width: UIMetrics.dayChipSize, height: UIMetrics.dayChipSize)
        }
    }

    private func arrow(_ symbol: String, _ label: String, _ enabled: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: UIMetrics.dayOffRemoveIconSize, weight: .heavy))
                .foregroundStyle(enabled ? Night.tracker : Night.faint)
                .frame(width: UIMetrics.dayChipSize, height: UIMetrics.dayChipSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(Text(verbatim: label))
    }
}
