import SathiCore
import SwiftUI

struct ReadingDoneCard: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.cornerSpacing) {
            header
            if let item = askedItem { ask(item) }
        }
        .modifier(CornerCard(width: UIMetrics.cornerDoneWidth))
    }

    private var askedItem: ReadingItem? {
        guard let id = e.celebration.readingAsk else { return nil }
        return e.data.prefs.reading.list.first { $0.id == id && $0.doneOn == nil }
    }

    private func ask(_ item: ReadingItem) -> some View {
        VStack(alignment: .leading, spacing: UIMetrics.cornerButtonSpacing) {
            Text(verbatim: Copywriter.readingAsk(item.displayTitle))
                .font(Typography.hint.bold())
                .foregroundStyle(Night.text)
                .lineLimit(1)
                .truncationMode(.tail)
            HStack(spacing: UIMetrics.cornerButtonSpacing) {
                Button {
                    e.markReadingDone(id: item.id)
                    e.endCelebrate()
                } label: { Text(Copywriter.readingYesDone).frame(maxWidth: .infinity) }
                    .buttonStyle(AccentButton(accent: Night.reading, height: UIMetrics.cornerButtonHeight))
                Button { e.endCelebrate() } label: { Text(Copywriter.readingNotYet) }
                    .buttonStyle(GhostButton(accent: Night.chipText, height: UIMetrics.cornerButtonHeight))
            }
        }
    }

    private var header: some View {
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
    }
}
