import SathiCore
import SwiftUI

struct BlockDonePopup: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        if let f = e.finishedBlock {
            VStack(alignment: .leading, spacing: UIMetrics.blockPopupSpacing) {
                BlockPopupHeader(
                    icon: "checkmark",
                    eyebrow: Copywriter.blockDoneEyebrow,
                    title: Copywriter.blockDoneSummary(minutes: minutes(f), title: f.block.title),
                    detail: Copywriter.blockSavedTo(
                        f.calendarTitle, start: f.block.startedAt, end: f.end, calendar: Calendar.gregorian(in: e.timeZone)
                    ),
                    dot: e.calendarChoices().first { $0.id == f.block.calendarID }?.colorHex,
                    onClose: { e.dismissBlockDone() }
                )
                BlockPopupActions(
                    primary: Copywriter.blockDone, primaryID: "block.done.done", onPrimary: { e.dismissBlockDone() },
                    secondary: Copywriter.blockExtendLabel, secondaryID: "block.done.extend", onSecondary: { e.extendBlock() }
                )
            }
            .modifier(CornerCard(width: UIMetrics.cornerWidth, border: Night.border))
        }
    }

    private func minutes(_ f: FinishedBlock) -> Int {
        Int((f.end.timeIntervalSince(f.block.startedAt) / Timing.minute).rounded())
    }
}
