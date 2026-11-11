import SathiCore
import SwiftUI

struct TodayComingUp: View {
    let items: [ComingUpItem]
    let calendar: Calendar
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.todayComingRowGap) {
            Text(verbatim: Copywriter.todayComingUpTitle)
                .font(Typography.tracker(UIMetrics.todayPanelTitleFont, .heavy))
                .foregroundStyle(Night.text)
            if items.isEmpty {
                Text(verbatim: Copywriter.todayNothingMore)
                    .font(Typography.tracker(UIMetrics.todayPanelNoteFont, .regular))
                    .foregroundStyle(Night.muted)
            }
            ForEach(items) { item in row(item) }
            Spacer(minLength: 0)
        }
        .padding(UIMetrics.todayPanelPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .todayCard()
    }

    private func row(_ item: ComingUpItem) -> some View {
        let tint = Self.tint(item.kind)
        return HStack(spacing: UIMetrics.todayComingRowGap) {
            Image(systemName: Self.icon(item.kind))
                .font(.system(size: UIMetrics.todayComingIcon, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: UIMetrics.todayComingTile, height: UIMetrics.todayComingTile)
                .background(RoundedRectangle(cornerRadius: UIMetrics.todayComingTileRadius).fill(tint.opacity(UIMetrics.todayComingTintOpacity)))
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: item.title)
                    .font(Typography.tracker(UIMetrics.todayComingTitleFont, .bold))
                    .foregroundStyle(Night.text)
                    .lineLimit(1)
                Text(verbatim: Copywriter.todayTimeAndDetail(item.time, detail: item.detail, calendar: calendar))
                    .font(Typography.tracker(UIMetrics.todayComingDetailFont, .regular))
                    .foregroundStyle(Night.muted)
            }
            Spacer(minLength: 0)
            Text(verbatim: Copywriter.todayInMinutes(item.time.timeIntervalSince(now)))
                .font(Typography.tracker(UIMetrics.todayComingBadgeFont, .heavy))
                .foregroundStyle(tint)
                .padding(UIMetrics.todayComingBadgePadding)
                .background(RoundedRectangle(cornerRadius: UIMetrics.todayComingBadgeRadius).fill(tint.opacity(UIMetrics.todayComingTintOpacity)))
        }
        .padding(UIMetrics.todayComingRowPadding)
        .background(RoundedRectangle(cornerRadius: UIMetrics.todayComingRowRadius, style: .continuous).fill(Night.trackerInset))
    }

    static func tint(_ kind: ComingUpKind) -> Color {
        switch kind {
        case .trackerAsk: return Night.tracker
        case .quick: return Night.quick
        case .daySummary: return Night.spark
        case let .habit(id): return Night.accent(id)
        }
    }

    static func icon(_ kind: ComingUpKind) -> String {
        switch kind {
        case .trackerAsk: return "clock"
        case .quick: return "bell"
        case .daySummary: return "moon"
        case let .habit(id):
            switch id {
            case .water: return "drop"
            case .reading: return "book"
            case .meditation: return "circle.circle"
            case .gym: return "dumbbell"
            }
        }
    }
}
