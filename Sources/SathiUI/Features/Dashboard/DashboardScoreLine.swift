import SathiCore
import SwiftUI

struct DashboardScoreLine: View {
    let score: DashboardScore

    var body: some View {
        Text(verbatim: Copywriter.dashboardScoreLine(met: score.met, possible: score.possible, change: score.changeText))
            .font(Typography.tracker(UIMetrics.dashboardScoreFont, .semibold))
            .foregroundStyle(score.isUp ? Night.sprout : Night.muted)
            .padding(.top, UIMetrics.dashboardScoreGap)
    }
}
