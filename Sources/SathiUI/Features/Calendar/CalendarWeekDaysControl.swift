import SathiCore
import SwiftUI

struct CalendarWeekDaysControl: View {
    let days: Int
    let pick: (Int) -> Void

    var body: some View {
        Menu {
            ForEach(Limits.calendarWeekDays, id: \.self) { n in
                Button(Copywriter.calendarWeekDaysOption(n)) { pick(n) }
            }
        } label: {
            label
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
        .accessibilityLabel(Copywriter.calendarWeekDaysLabel)
    }

    private var label: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.rangeArrowRadius, style: .continuous)
        return HStack(spacing: UIMetrics.calendarRowZoomGap) {
            Text(verbatim: Copywriter.calendarWeekDaysOption(days))
                .font(Typography.chip)
                .foregroundStyle(Night.text)
            Image(systemName: "chevron.down")
                .font(.system(size: UIMetrics.blockChevron, weight: .heavy))
                .foregroundStyle(Night.muted)
        }
        .padding(UIMetrics.calendarTodayPadding)
        .frame(height: UIMetrics.rangeArrowSize)
        .background(shape.fill(Night.card))
        .overlay(shape.strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
        .contentShape(shape)
    }
}
