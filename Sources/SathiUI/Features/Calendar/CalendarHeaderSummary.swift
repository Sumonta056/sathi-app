import SathiCore
import SwiftUI

struct CalendarHeaderSummary: View {
    let stats: CalendarPageStats

    var body: some View {
        (label(Copywriter.calendarTracked + " ")
            + value(Copywriter.calendarHours(stats.tracked))
            + label(Copywriter.calendarSummaryGap + Copywriter.calendarPlanned + " ")
            + value(Copywriter.calendarHours(stats.planned)))
            .lineLimit(1)
            .fixedSize()
    }

    private func label(_ text: String) -> Text {
        Text(verbatim: text)
            .font(Typography.tracker(UIMetrics.calendarSummaryFont, .medium))
            .foregroundColor(Night.muted)
    }

    private func value(_ text: String) -> Text {
        Text(verbatim: text)
            .font(Typography.tracker(UIMetrics.calendarSummaryFont, .bold))
            .foregroundColor(Night.text)
    }
}
