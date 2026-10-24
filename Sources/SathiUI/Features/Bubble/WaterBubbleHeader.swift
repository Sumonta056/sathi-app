import SathiCore
import SwiftUI

struct WaterBubbleHeader: View {
    @EnvironmentObject var e: Engine
    let level: Level

    private var eyebrow: String {
        let time = e.now.formatted(date: .omitted, time: .shortened)
        if level == .persist { return "STILL WAITING · SNOOZED \(e.state(.water).snoozes)× · \(time)" }
        return "WATER · \(time)"
    }

    var body: some View {
        HStack(alignment: .top, spacing: UIMetrics.bubbleHeaderSpacing) {
            BobbingBuddy(habit: .water)
            VStack(alignment: .leading, spacing: UIMetrics.textSpacing) {
                Text(eyebrow)
                    .font(Typography.eyebrow)
                    .tracking(UIMetrics.labelTracking)
                    .foregroundStyle(Night.water)
                Text(e.copy.title)
                    .font(Typography.bubbleTitle)
                    .foregroundStyle(Night.text)
                    .fixedSize(horizontal: false, vertical: true)
                Text(e.copy.body)
                    .font(Typography.hint)
                    .foregroundStyle(Night.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
