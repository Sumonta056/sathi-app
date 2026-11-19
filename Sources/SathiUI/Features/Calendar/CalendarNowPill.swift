import SathiCore
import SwiftUI

struct CalendarNowPill: View {
    let now: Date
    let calendar: Calendar

    var body: some View {
        Text(verbatim: Copywriter.trackerClock(now, calendar: calendar))
            .font(Typography.tracker(UIMetrics.calendarNowPillFont, .bold))
            .foregroundStyle(Night.onAccent)
            .padding(UIMetrics.calendarNowPillPadding)
            .frame(height: UIMetrics.calendarNowPillHeight)
            .background(Capsule().fill(Night.calendarNow))
            .fixedSize()
            .allowsHitTesting(false)
            .accessibilityIdentifier("calendar.now.pill")
    }
}
