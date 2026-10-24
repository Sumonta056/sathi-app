import SathiCore
import SwiftUI

struct MenuHeader: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: UIMetrics.textSpacing) {
                Text(e.greeting)
                    .font(Typography.heroTitle)
                    .foregroundStyle(Night.text)
                Text(subline)
                    .font(Typography.hint)
                    .foregroundStyle(Night.muted)
            }
            Spacer()
            Image(systemName: "leaf.fill")
                .font(.system(size: UIMetrics.logoIconSize, weight: .bold))
                .foregroundStyle(Night.onAccent)
                .frame(width: UIMetrics.logoSize, height: UIMetrics.logoSize)
                .background(Circle().fill(Night.sprout))
                .accessibilityHidden(true)
        }
    }

    private var subline: String {
        let date = e.now.formatted(.dateTime.weekday(.wide).day().month(.wide))
        let best = e.bestStreak
        return best > 0 ? "\(date) · \(best)-day streak" : date
    }
}
