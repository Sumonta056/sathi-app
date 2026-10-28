import SathiCore
import SwiftUI

struct DaySummaryCard: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let summary = e.daySummary
        VStack(alignment: .leading, spacing: UIMetrics.cornerSpacing) {
            header(summary)
            VStack(alignment: .leading, spacing: UIMetrics.summaryRowsSpacing) {
                ForEach(summary.rows, id: \.id) { DaySummaryRowView(row: $0) }
            }
            Button { e.closeDaySummary() } label: {
                Text("Good night").frame(maxWidth: .infinity)
            }
            .buttonStyle(AccentButton(accent: Night.sprout, height: UIMetrics.cornerButtonHeight))
        }
        .modifier(CornerCard(border: Night.fieldBorder))
    }

    private func header(_ summary: DaySummary) -> some View {
        HStack(alignment: .top, spacing: UIMetrics.cornerRowSpacing) {
            StaticBuddy(habit: .water, size: UIMetrics.cornerBuddySize)
            VStack(alignment: .leading, spacing: UIMetrics.cornerTextSpacing) {
                Text(eyebrow(summary.verdict))
                    .font(Typography.eyebrow)
                    .foregroundStyle(Night.sprout)
                Text(Copywriter.daySummaryTitle(summary.verdict, name: e.data.prefs.general.name))
                    .font(Typography.cornerTitle)
                    .foregroundStyle(Night.text)
                    .lineLimit(1)
                    .minimumScaleFactor(UIMetrics.summaryTitleMinScale)
                Text(Copywriter.daySummaryHint(summary.verdict))
                    .font(Typography.hint)
                    .foregroundStyle(Night.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            CornerCloseButton(label: "Close") { e.closeDaySummary() }
        }
    }

    private func eyebrow(_ verdict: DaySummaryVerdict) -> String {
        switch verdict {
        case .allMet: return "TODAY · ALL DONE"
        case .restDay: return "DAY OFF"
        case .someMet, .noneMet: return "TODAY"
        }
    }
}
