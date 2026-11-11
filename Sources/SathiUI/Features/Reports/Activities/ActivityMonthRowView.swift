import SathiCore
import SwiftUI

struct ActivityMonthRowView: View {
    let day: DayKey
    let row: ActivityMonthRow?
    let categories: [ActivityCategory]
    let calendar: Calendar
    let open: () -> Void

    var body: some View {
        Button(action: open) {
            HStack(spacing: UIMetrics.reportsGap) {
                Text(verbatim: Copywriter.trackerShortDate(day.start(in: calendar), calendar: calendar))
                    .font(Typography.rowLabel).foregroundStyle(Night.text)
                    .frame(width: UIMetrics.trackerMonthDayWidth, alignment: .leading)
                Text(verbatim: row.map { Copywriter.categoryTableHours($0.realWork) } ?? Copywriter.noValue)
                    .font(Typography.hint).foregroundStyle(Night.muted)
                    .frame(width: UIMetrics.trackerMonthHoursWidth, alignment: .leading)
                strip
                Text(verbatim: row?.topTexts.joined(separator: ", ") ?? "")
                    .font(Typography.hint).foregroundStyle(Night.muted).lineLimit(1)
                    .frame(width: UIMetrics.trackerMonthTopWidth, alignment: .leading)
            }
            .padding(.vertical, UIMetrics.trackerLogRowPadding)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var strip: some View {
        if let row {
            ActivityRibbon(
                segments: row.segments, hours: row.hours, categories: categories,
                height: UIMetrics.trackerMonthStripHeight, radius: UIMetrics.trackerBarRadius, showsLabels: false
            )
        } else {
            RoundedRectangle(cornerRadius: UIMetrics.trackerBarRadius, style: .continuous)
                .fill(Night.divider)
                .frame(height: UIMetrics.trackerMonthStripHeight)
        }
    }
}
