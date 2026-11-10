import SathiCore
import SwiftUI

struct WelcomePlaces: View {
    let state: TrackerPromptState

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.trackerPlaceBoxSpacing) {
            HStack(spacing: UIMetrics.trackerChipSpacing) {
                Text(verbatim: Copywriter.trackerWhereWereYou)
                    .font(Typography.tracker(UIMetrics.trackerPillFont, .bold))
                    .foregroundStyle(Night.label)
                Text(verbatim: Copywriter.trackerOptional)
                    .font(Typography.tracker(UIMetrics.trackerPillFont, .medium))
                    .foregroundStyle(Night.faint)
            }
            HStack(spacing: UIMetrics.trackerChipSpacing) {
                ForEach(AwayPlace.choices, id: \.self) { place in
                    TrackerChip(
                        label: Copywriter.trackerAwayPlace(place),
                        on: state.away?.place == place,
                        id: "tracker.place." + place.rawValue,
                        font: UIMetrics.trackerPlaceFont
                    ) { state.actions.pickPlace(place) }
                }
            }
        }
        .trackerBox(padding: UIMetrics.trackerPlaceBoxPadding, radius: UIMetrics.trackerPlaceBoxRadius)
    }
}

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
