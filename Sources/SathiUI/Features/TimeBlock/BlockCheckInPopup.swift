import SathiCore
import SwiftUI

struct BlockCheckInPopup: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        if let b = e.timeBlock, b.isRunning {
            VStack(alignment: .leading, spacing: UIMetrics.blockPopupSpacing) {
                BlockPopupHeader(
                    icon: "clock",
                    eyebrow: Copywriter.blockCheckInEyebrow,
                    title: Copywriter.blockStillOn(b.title),
                    detail: Copywriter.blockStartedAt(b.startedAt, calendar: Calendar.gregorian(in: e.timeZone))
                )
                BlockPopupActions(
                    primary: Copywriter.blockKeepGoing, primaryID: "block.checkin.keep", onPrimary: { e.keepGoingBlock() },
                    secondary: Copywriter.blockEndNow, secondaryID: "block.checkin.end", onSecondary: { e.endBlock() }
                )
            }
            .modifier(CornerCard(width: UIMetrics.cornerWidth, border: Night.border))
        }
    }
}
