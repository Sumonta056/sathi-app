import SathiCore
import SwiftUI

struct GymThanks: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        HStack(alignment: .center, spacing: UIMetrics.cornerRowSpacing) {
            StaticBuddy(habit: .gym, size: UIMetrics.cornerDoneBuddySize)
            VStack(alignment: .leading, spacing: UIMetrics.cornerTextSpacing) {
                Text(e.celebration.title)
                    .font(Typography.cardTitle)
                    .foregroundStyle(Night.text)
                Text("Shokti counted this move.")
                    .font(Typography.hint)
                    .foregroundStyle(Night.muted)
            }
            Spacer(minLength: 0)
            CornerCloseButton(label: "Close") { e.endCelebrate() }
        }
        .modifier(CornerCard(width: UIMetrics.cornerDoneWidth, habit: .gym))
    }
}
