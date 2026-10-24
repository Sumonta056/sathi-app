import SathiCore
import SwiftUI

struct WaterThanks: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let goal = e.goalText(.water)
        VStack(spacing: UIMetrics.thanksSpacing) {
            ZStack {
                SparkBurst()
                BobbingBuddy(habit: .water, size: UIMetrics.thanksBuddySize)
            }
            Text(e.celebration.title)
                .font(Typography.thanksTitle)
                .foregroundStyle(Night.text)
            Text("\(goal.done) \(goal.rest) today")
                .font(Typography.hint)
                .foregroundStyle(Night.muted)
            DropsRow(total: e.glassesToday, goal: DropsRow.drops(goal: e.data.prefs.water.dailyGoalGlasses))
            Button { e.endCelebrate() } label: {
                Text(e.waterSeeYou).frame(maxWidth: .infinity)
            }
            .buttonStyle(AccentButton(
                accent: Night.water,
                height: UIMetrics.thanksButtonHeight,
                radius: UIMetrics.thanksButtonRadius
            ))
        }
        .padding(UIMetrics.bubblePadding)
        .modifier(WaterCard())
        .padding(UIMetrics.bubbleShadowPadding)
        .environment(\.colorScheme, .dark)
    }
}
