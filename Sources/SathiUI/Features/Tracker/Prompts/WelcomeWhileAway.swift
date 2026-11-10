import SathiCore
import SwiftUI

struct WelcomeWhileAway: View {
    let state: TrackerPromptState

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.trackerPlaceBoxSpacing) {
            Text(verbatim: Copywriter.trackerWhileAway)
                .font(Typography.tracker(TrackerSize.center.eyebrow, .heavy))
                .tracking(TrackerSize.center.eyebrow * UIMetrics.trackerEyebrowEm)
                .foregroundStyle(Night.label)
            ForEach(state.loggedWhileAway, id: \.id) { row($0) }
        }
        .trackerBox(padding: UIMetrics.trackerPlaceBoxPadding, radius: UIMetrics.trackerPlaceBoxRadius)
    }

    private func row(_ a: Activity) -> some View {
        HStack(spacing: UIMetrics.trackerOptionRowSpacing) {
            VStack(alignment: .leading, spacing: UIMetrics.trackerLineGap) {
                Text(verbatim: a.text)
                    .font(Typography.tracker(UIMetrics.trackerPlaceFont, .bold))
                    .foregroundStyle(Night.text)
                    .lineLimit(1)
                Text(verbatim: Copywriter.trackerSpan(a.start, a.end, calendar: state.calendar) + " · " + Copywriter.trackerLogged)
                    .font(Typography.tracker(UIMetrics.trackerDetailFont, .medium))
                    .foregroundStyle(Night.muted)
            }
            Spacer(minLength: 0)
            if let eventID = a.sourceEventID {
                TrackerChip(label: Copywriter.trackerNotAttending, on: false, id: "tracker.notAttending") {
                    state.actions.notAttending(eventID)
                }
            }
        }
    }
}
