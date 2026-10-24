import SathiCore
import SwiftUI

struct ReadingDoneCard: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        HStack(alignment: .center, spacing: UIMetrics.cornerRowSpacing) {
            StaticBuddy(habit: .reading, size: UIMetrics.cornerDoneBuddySize)
            VStack(alignment: .leading, spacing: UIMetrics.cornerTextSpacing) {
                Text(Copywriter.readingDoneTitle(minutes: Int(e.celebration.amount)))
                    .font(Typography.cardTitle)
                    .foregroundStyle(Night.text)
                Text(Copywriter.readingDoneHint(streak: e.streak(.reading)))
                    .font(Typography.hint)
                    .foregroundStyle(Night.muted)
            }
            Spacer(minLength: 0)
            CornerCloseButton(label: "Close") { e.endCelebrate() }
        }
        .modifier(CornerCard(width: UIMetrics.cornerDoneWidth))
    }
}
