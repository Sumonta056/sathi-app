import SathiCore
import SwiftUI

struct CalendarGonePopup: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        if let b = e.timeBlock, b.waitingForCalendar {
            let state = e.waitingSaveState
            VStack(alignment: .leading, spacing: UIMetrics.blockCardSpacing) {
                BlockPopupHeader(
                    eyebrow: Copywriter.blockGoneEyebrow,
                    eyebrowColor: Night.spark,
                    title: headline(b, state),
                    detail: detail(b, state)
                )
                WaitingSaveAction(idPrefix: "block.gone.")
            }
            .modifier(CornerCard(width: UIMetrics.cornerWidth, border: Night.border))
        }
    }

    private func headline(_ b: TimeBlock, _ state: WaitingSaveState) -> String {
        if state == .noAccess { return Copywriter.blockNoAccessHeadline }
        guard let name = e.calendarTitle(b.calendarID) else { return Copywriter.blockCalendarGone(b.calendarTitle) }
        return Copywriter.blockSaveFailed(name)
    }

    private func detail(_ b: TimeBlock, _ state: WaitingSaveState) -> String {
        switch state {
        case .noAccess: Copywriter.blockNoAccessDetail(minutes: minutes(b), title: b.title)
        case .noCalendar, .choose: Copywriter.blockChooseCalendar(minutes: minutes(b), title: b.title)
        }
    }

    private func minutes(_ b: TimeBlock) -> Int {
        Int(((b.endedAt ?? e.now).timeIntervalSince(b.startedAt) / Timing.minute).rounded(.down))
    }
}
