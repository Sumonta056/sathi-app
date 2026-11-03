import SathiCore
import SwiftUI

struct CalendarGonePopup: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        if let b = e.timeBlock, b.waitingForCalendar {
            VStack(alignment: .leading, spacing: UIMetrics.blockCardSpacing) {
                BlockPopupHeader(
                    eyebrow: Copywriter.blockGoneEyebrow,
                    eyebrowColor: Night.spark,
                    title: headline(b),
                    detail: Copywriter.blockChooseCalendar(minutes: minutes(b), title: b.title)
                )
                BlockSaveHere(idPrefix: "block.gone.")
            }
            .modifier(CornerCard(width: UIMetrics.cornerWidth, border: Night.border))
        }
    }

    private func headline(_ b: TimeBlock) -> String {
        guard let name = e.calendarTitle(b.calendarID) else { return Copywriter.blockCalendarGone(b.calendarTitle) }
        return Copywriter.blockSaveFailed(name)
    }

    private func minutes(_ b: TimeBlock) -> Int {
        Int(((b.endedAt ?? e.now).timeIntervalSince(b.startedAt) / Timing.minute).rounded(.down))
    }
}
