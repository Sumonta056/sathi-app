import SathiCore
import SwiftUI

struct TrackerSwitchRow: View {
    let times: [Date]
    @Binding var picked: Date?
    let calendar: Calendar

    var body: some View {
        HStack(alignment: .center, spacing: UIMetrics.trackerOptionRowSpacing) {
            Text(verbatim: Copywriter.trackerStarted)
                .font(Typography.tracker(TrackerSize.corner.label, .bold))
                .foregroundStyle(Night.label)
                .frame(width: TrackerSize.corner.labelWidth, alignment: .leading)
            if times.count > Limits.switchChipsBeforeGrid {
                TimeMenu(minutes: gridMinutes, accent: Night.tracker, active: true)
                    .accessibilityIdentifier("tracker.switch.grid")
            } else {
                HStack(spacing: UIMetrics.trackerChipSpacing) {
                    ForEach(times, id: \.self) { time in
                        TrackerChip(
                            label: label(time), on: picked == time, id: "tracker.switch.chip",
                            height: TrackerSize.corner.chipHeight, padding: TrackerSize.corner.chipPadding, font: TrackerSize.corner.chipFont
                        ) { picked = time }
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var gridMinutes: Binding<Int> {
        Binding(
            get: { TrackerSwitchPick.minutes(of: picked ?? times.last ?? Date(), calendar: calendar) },
            set: { picked = TrackerSwitchPick.nearest(to: $0, in: times, calendar: calendar) }
        )
    }

    private func label(_ time: Date) -> String {
        time == times.last ? Copywriter.trackerNow : Copywriter.trackerClock(time, calendar: calendar)
    }
}
