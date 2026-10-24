import SathiCore
import SwiftUI

struct MeditationThanks: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        VStack(spacing: UIMetrics.calmSpacing) {
            BobbingBuddy(habit: .meditation, size: UIMetrics.calmThanksBuddySize)
            Text(e.celebration.title)
                .font(Typography.thanksTitle)
                .foregroundStyle(Night.text)
                .multilineTextAlignment(.center)
            Text(Copywriter.calmThanksHint(streak: e.streak(.meditation)))
                .font(Typography.hint)
                .foregroundStyle(Night.muted)
            Button { e.endCelebrate() } label: {
                Text("Back to work").frame(maxWidth: .infinity)
            }
            .buttonStyle(AccentButton(accent: Night.calm, height: UIMetrics.calmButtonHeight, text: Night.calmGround))
        }
        .modifier(CalmCard())
    }
}
