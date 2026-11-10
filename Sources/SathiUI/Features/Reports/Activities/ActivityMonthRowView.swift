import SathiCore
import SwiftUI

struct ActivityMonthRowView: View {
    let row: ActivityMonthRow
    let categories: [ActivityCategory]
    let calendar: Calendar
    let open: () -> Void

    var body: some View {
        Button(action: open) {
            HStack(spacing: UIMetrics.reportsGap) {
                Text(verbatim: Copywriter.trackerShortDate(row.day.start(in: calendar), calendar: calendar))
                    .font(Typography.rowLabel).foregroundStyle(Night.text)
                    .frame(width: UIMetrics.trackerMonthDayWidth, alignment: .leading)
                Text(verbatim: Copywriter.trackerTileDuration(row.realWork))
                    .font(Typography.hint).foregroundStyle(Night.muted)
                    .frame(width: UIMetrics.trackerMonthHoursWidth, alignment: .leading)
                ActivityRibbon(
                    segments: row.segments, hours: row.hours, categories: categories,
                    height: UIMetrics.trackerMonthStripHeight, radius: UIMetrics.trackerBarRadius, showsLabels: false
                )
                Text(verbatim: row.topTexts.joined(separator: ", "))
                    .font(Typography.hint).foregroundStyle(Night.muted).lineLimit(1)
                    .frame(width: UIMetrics.trackerMonthTopWidth, alignment: .leading)
            }
            .padding(.vertical, UIMetrics.trackerLogRowPadding)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
