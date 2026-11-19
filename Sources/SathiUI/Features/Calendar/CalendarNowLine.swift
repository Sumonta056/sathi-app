import SwiftUI

struct CalendarNowLine: View {
    var body: some View {
        ZStack(alignment: .leading) {
            Night.calendarNow.frame(height: UIMetrics.calendarNowLineWidth)
            Circle()
                .fill(Night.calendarNow)
                .frame(width: UIMetrics.calendarNowDot, height: UIMetrics.calendarNowDot)
        }
        .allowsHitTesting(false)
        .accessibilityIdentifier("calendar.now")
    }
}
