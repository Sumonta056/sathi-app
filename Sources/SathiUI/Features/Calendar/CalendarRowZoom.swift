import SathiCore
import SwiftUI

struct CalendarRowZoom: View {
    @Binding var minutes: Int

    var body: some View {
        HStack(spacing: UIMetrics.calendarRowZoomGap) {
            Text(verbatim: Copywriter.calendarRowLabel)
                .font(Typography.chip)
                .foregroundStyle(Night.muted)
            PillSegment(options: Limits.calendarRowMinutes, selected: $minutes, title: Copywriter.calendarRowOption)
        }
        .fixedSize()
    }
}
