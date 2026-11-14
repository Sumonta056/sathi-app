import SathiCore
import SwiftUI

struct CalendarNowLine: View {
    let now: Date
    let calendar: Calendar
    var showsTime = true

    var body: some View {
        ZStack(alignment: .leading) {
            Night.calendarNow.frame(height: UIMetrics.calendarNowLineWidth)
            if showsTime {
                Text(verbatim: Copywriter.trackerClock(now, calendar: calendar))
                    .font(Typography.tracker(UIMetrics.calendarNowPillFont, .bold))
                    .foregroundStyle(Night.onAccent)
                    .padding(UIMetrics.calendarNowPillPadding)
                    .background(Capsule().fill(Night.calendarNow))
                    .fixedSize()
            } else {
                Circle().fill(Night.calendarNow).frame(width: UIMetrics.calendarNowDot, height: UIMetrics.calendarNowDot)
            }
        }
        .allowsHitTesting(false)
        .accessibilityIdentifier("calendar.now")
    }
}
