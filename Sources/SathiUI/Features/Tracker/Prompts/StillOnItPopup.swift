import SathiCore
import SwiftUI

struct StillOnItPopup: View {
    let state: TrackerPromptState

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.trackerStillSpacing) {
            TrackerHeader(
                icon: "clock", eyebrow: eyebrow, title: state.running?.text ?? "", detail: state.isLate ? detail : nil, dot: dot
            )
            if let waited = state.waitedMinutes { late(waited) } else { onTime }
        }
        .trackerCornerCard()
    }

    @ViewBuilder private func late(_ waited: Int) -> some View {
        TrackerHint(text: Copywriter.trackerWaited(waited))
        HStack(spacing: UIMetrics.trackerButtonSpacing) {
            TrackerPrimaryButton(label: Copywriter.trackerStillOnIt, id: "tracker.stillLate", height: UIMetrics.trackerStillButton) {
                state.actions.stillOnLate()
            }
            outline(Copywriter.trackerDonePick, "tracker.done") { state.actions.done() }
        }
    }

    @ViewBuilder private var onTime: some View {
        TrackerPrimaryButton(
            label: Copywriter.trackerYesMore(state.askEveryMinutes), id: "tracker.still", height: UIMetrics.trackerStillButton
        ) { state.actions.stillOn(nil) }
        HStack(spacing: UIMetrics.trackerChipSpacing) {
            Text(verbatim: Copywriter.trackerOrMore)
                .font(Typography.tracker(UIMetrics.trackerPillFont, .bold))
                .foregroundStyle(Night.label)
                .padding(.trailing, UIMetrics.trackerLineGap)
            ForEach(Self.laterChoices, id: \.self) { minutes in
                TrackerChip(label: Copywriter.trackerMinutesChip(minutes), on: false, id: "tracker.in.\(minutes)") {
                    state.actions.stillOn(minutes)
                }
            }
        }
        HStack(spacing: UIMetrics.trackerButtonSpacing) {
            outline(Copywriter.trackerDonePick, "tracker.done") { state.actions.done() }
            outline(Copywriter.trackerSkip, "tracker.skip", width: UIMetrics.trackerStillSkipWidth) { state.actions.skip(nil) }
        }
    }

    private func outline(_ label: String, _ id: String, width: CGFloat? = nil, action: @escaping () -> Void) -> some View {
        TrackerSecondaryButton(
            label: label, id: id, height: UIMetrics.trackerOutlineHeight, width: width, font: UIMetrics.trackerOutlineFont,
            weight: width == nil ? .bold : .semibold, color: width == nil ? Night.text : Night.muted, action: action
        )
    }

    private static let laterChoices = [5, 30]

    private var eyebrow: String {
        guard !state.isLate, let running = state.running else {
            return Copywriter.trackerStillOnEyebrow(state.shownAt, late: state.isLate, calendar: state.calendar)
        }
        return Copywriter.trackerStillSoFarEyebrow(max(0, Int(state.now.timeIntervalSince(running.start) / Timing.minute)))
    }

    private var dot: UInt32? {
        state.categories.first { $0.name == state.running?.category }?.colorHex
    }

    private var detail: String? {
        state.running.map {
            Copywriter.trackerStillSub(
                category: $0.category, since: $0.start, length: $0.expectedLength, calendar: state.calendar
            )
        }
    }
}
