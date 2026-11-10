import SathiCore
import SwiftUI

struct StillOnItPopup: View {
    let state: TrackerPromptState

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.trackerPopupSpacing) {
            TrackerHeader(
                icon: "hourglass",
                eyebrow: Copywriter.trackerStillOnEyebrow(state.shownAt, late: state.isLate, calendar: state.calendar),
                title: state.running?.text ?? "",
                detail: detail
            )
            if let waited = state.waitedMinutes {
                Text(verbatim: Copywriter.trackerWaited(waited))
                    .font(Typography.hint)
                    .foregroundStyle(Night.chipText)
                HStack(spacing: UIMetrics.trackerButtonSpacing) {
                    TrackerPrimaryButton(label: Copywriter.trackerStillOnIt, id: "tracker.stillLate") {
                        state.actions.stillOnLate()
                    }
                    TrackerSecondaryButton(label: Copywriter.trackerDonePick, id: "tracker.done") { state.actions.done() }
                }
            } else {
                TrackerPrimaryButton(
                    label: Copywriter.trackerYesMore(state.askEveryMinutes), id: "tracker.still"
                ) { state.actions.stillOn(nil) }
                HStack(spacing: UIMetrics.trackerChipSpacing) {
                    Text(verbatim: Copywriter.trackerOrAskIn)
                        .font(Typography.hint)
                        .foregroundStyle(Night.muted)
                    ForEach(Self.laterChoices, id: \.self) { minutes in
                        TrackerChip(label: Copywriter.trackerMinutesChip(minutes), on: false, id: "tracker.in.\(minutes)") {
                            state.actions.stillOn(minutes)
                        }
                    }
                    Spacer(minLength: 0)
                }
                HStack(spacing: UIMetrics.trackerButtonSpacing) {
                    TrackerSecondaryButton(label: Copywriter.trackerDone, id: "tracker.done") { state.actions.done() }
                    TrackerSecondaryButton(
                        label: Copywriter.trackerSkip, id: "tracker.skip", width: UIMetrics.trackerSkipWidth
                    ) { state.actions.skip(nil) }
                }
            }
        }
        .trackerCornerCard()
    }

    private static let laterChoices = [5, 30]

    private var detail: String? {
        state.running.map {
            Copywriter.trackerStillSub(
                category: $0.category, since: $0.start, length: $0.expectedLength, calendar: state.calendar
            )
        }
    }
}
