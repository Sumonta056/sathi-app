import SathiCore
import SwiftUI

struct ActivityDatePicker: View {
    let selected: DayKey
    let calendar: Calendar
    let marks: (MonthKey) -> Set<DayKey>
    let pick: (DayKey) -> Void
    @State private var month: MonthKey

    init(selected: DayKey, calendar: Calendar, marks: @escaping (MonthKey) -> Set<DayKey>, pick: @escaping (DayKey) -> Void) {
        self.selected = selected
        self.calendar = calendar
        self.marks = marks
        self.pick = pick
        _month = State(initialValue: MonthKey(selected.start(in: calendar), calendar: calendar))
    }

    var body: some View {
        let cells = Self.cells(month, calendar: calendar)
        let dotted = marks(month)
        VStack(spacing: UIMetrics.calendarSpacing) {
            HStack {
                arrow("chevron.left", "Previous month") { month = month.previous }
                Spacer()
                Text(verbatim: Copywriter.trackerMonthTitle(month.start(in: calendar), calendar: calendar))
                    .font(Typography.chip)
                    .foregroundStyle(Night.text)
                Spacer()
                arrow("chevron.right", "Next month") { month = month.next }
            }
            ForEach(Array(cells.enumerated()), id: \.offset) { _, week in
                HStack(spacing: UIMetrics.calendarSpacing) {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, key in
                        cell(key, dotted: dotted)
                    }
                }
            }
        }
        .padding(UIMetrics.trackerPickerPadding)
        .frame(width: UIMetrics.trackerPickerWidth)
        .background(Night.card)
        .environment(\.colorScheme, .dark)
    }

    static func cells(_ month: MonthKey, calendar: Calendar) -> [[DayKey?]] {
        let g = Calendar.gregorian(in: calendar.timeZone)
        let first = month.start(in: calendar)
        let count = g.range(of: .day, in: .month, for: first)?.count ?? 0
        let lead = (g.component(.weekday, from: first) - calendar.firstWeekday + 7) % 7
        var days: [DayKey?] = Array(repeating: nil, count: lead)
        for i in 0 ..< count {
            days.append(g.date(byAdding: .day, value: i, to: first).map { DayKey($0, calendar: calendar) })
        }
        while days.count % 7 != 0 {
            days.append(nil)
        }
        return stride(from: 0, to: days.count, by: 7).map { Array(days[$0 ..< $0 + 7]) }
    }

    private func arrow(_ symbol: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .foregroundStyle(Night.tracker)
                .frame(width: UIMetrics.trackerPickerCell, height: UIMetrics.trackerPickerCell)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: label))
    }

    @ViewBuilder
    private func cell(_ key: DayKey?, dotted: Set<DayKey>) -> some View {
        if let key {
            let on = key == selected
            let number = Int(key.raw.suffix(2)) ?? 0
            Button { pick(key) } label: {
                VStack(spacing: 0) {
                    Text(verbatim: "\(number)")
                        .font(Typography.chip)
                        .foregroundStyle(on ? Night.trackerOnAccent : Night.text)
                    Circle()
                        .fill(dotted.contains(key) ? (on ? Night.trackerOnAccent : Night.tracker) : .clear)
                        .frame(width: UIMetrics.trackerPickerDot, height: UIMetrics.trackerPickerDot)
                }
                .frame(width: UIMetrics.trackerPickerCell, height: UIMetrics.trackerPickerCell)
                .background(RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous).fill(on ? Night.tracker : .clear))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: key.raw))
            .accessibilityValue(Text(verbatim: dotted.contains(key) ? Copywriter.trackerHasActivities : ""))
        } else {
            Color.clear.frame(width: UIMetrics.trackerPickerCell, height: UIMetrics.trackerPickerCell)
        }
    }
}
