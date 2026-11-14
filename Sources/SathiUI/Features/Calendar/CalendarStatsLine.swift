import SathiCore
import SwiftUI

struct CalendarStatsLine: View {
    let stats: CalendarPageStats
    let kind: ReportRange

    var body: some View {
        Text(verbatim: Copywriter.calendarStatsLine(stats, kind: kind))
            .font(Typography.tracker(UIMetrics.calendarStatsLineFont, .semibold))
            .foregroundStyle(Night.muted)
    }
}
