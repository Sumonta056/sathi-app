import SathiCore
import SwiftUI

struct TodayComingUp: View {
    let items: [ComingUpItem]
    let calendar: Calendar

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.todayPanelGap) {
            Text(verbatim: Copywriter.todayComingUpTitle)
                .font(Typography.tracker(UIMetrics.todayPanelTitleFont, .bold))
                .foregroundStyle(Night.text)
            if items.isEmpty {
                Text(verbatim: Copywriter.todayNothingMore)
                    .font(Typography.tracker(UIMetrics.todayPanelNoteFont, .regular))
                    .foregroundStyle(Night.muted)
            }
            ForEach(items) { item in
                HStack(spacing: UIMetrics.todayComingGap) {
                    Text(verbatim: Copywriter.trackerClock(item.time, calendar: calendar))
                        .foregroundStyle(Night.muted)
                        .frame(width: UIMetrics.todayComingTimeWidth, alignment: .leading)
                    Text(verbatim: item.title)
                        .foregroundStyle(color(item.kind))
                        .lineLimit(1)
                }
                .font(Typography.tracker(UIMetrics.todayPanelNoteFont, .regular))
            }
            Spacer(minLength: 0)
        }
        .padding(UIMetrics.todayPanelPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: UIMetrics.todayCardRadius, style: .continuous).fill(Night.card))
        .overlay(RoundedRectangle(cornerRadius: UIMetrics.todayCardRadius, style: .continuous).stroke(Night.border))
    }

    private func color(_ kind: ComingUpKind) -> Color {
        switch kind {
        case .trackerAsk: return Night.tracker
        case .quick: return Night.quick
        case .habit, .daySummary: return Night.text
        }
    }
}
