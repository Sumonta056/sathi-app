import SathiCore
import SwiftUI

struct TrackerStatusBlock: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let prefs = e.data.prefs.tracker
        VStack(alignment: .leading, spacing: UIMetrics.mainStatusSpacing) {
            Text(verbatim: prefs.isOn ? Copywriter.mainTrackerOn : Copywriter.mainTrackerOff)
                .font(Typography.tracker(UIMetrics.mainStatusTitleFont, .bold))
                .tracking(UIMetrics.mainStatusTitleTracking)
                .foregroundStyle(prefs.isOn ? Night.tracker : Night.muted)
            if prefs.isOn {
                Text(verbatim: hours(prefs))
                    .font(Typography.tracker(UIMetrics.mainStatusFont, .regular))
                    .foregroundStyle(Night.muted)
            }
        }
        .padding(UIMetrics.mainStatusPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: UIMetrics.mainStatusRadius, style: .continuous).fill(Night.card))
        .overlay(RoundedRectangle(cornerRadius: UIMetrics.mainStatusRadius, style: .continuous).stroke(Night.border))
    }

    private func hours(_ prefs: TrackerPrefs) -> String {
        let cal = e.rangeCalendar
        let day = cal.startOfDay(for: e.now)
        let start = day.addingTimeInterval(TimeInterval(prefs.startMinutes) * Timing.minute)
        let end = day.addingTimeInterval(TimeInterval(prefs.endMinutes) * Timing.minute)
        return Copywriter.mainTrackerHours(start, end, askEvery: prefs.askEveryMinutes, calendar: cal)
    }
}
