import SathiCore
import SwiftUI

struct ActivityGapRow: View {
    let interval: DateInterval
    let calendar: Calendar
    let onFill: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.trackerMiniRadius, style: .continuous)
        HStack(spacing: UIMetrics.activitiesRowInner) {
            Text(verbatim: Copywriter.activitiesGap(Copywriter.trackerSpan(interval.start, interval.end, calendar: calendar)))
                .font(Typography.tracker(UIMetrics.activitiesGapFont, .medium))
                .foregroundStyle(Night.muted)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(verbatim: Copywriter.activitiesLength(interval.duration))
                .font(Typography.tracker(UIMetrics.activitiesGapFont, .bold))
                .foregroundStyle(Night.chipText)
                .fixedSize()
            Button(action: onFill) {
                Text(verbatim: "+")
                    .font(Typography.tracker(UIMetrics.activitiesRowTitleFont, .heavy))
                    .foregroundStyle(Night.tracker)
                    .frame(width: UIMetrics.activitiesPencil, height: UIMetrics.activitiesPlusHeight)
                    .background(RoundedRectangle(cornerRadius: UIMetrics.promptBoxRadius, style: .continuous).fill(Night.trackerFill))
                    .overlay(RoundedRectangle(cornerRadius: UIMetrics.promptBoxRadius, style: .continuous)
                        .strokeBorder(Night.trackerNowBorder, lineWidth: UIMetrics.cardBorder))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: Copywriter.activitiesFillGap))
        }
        .padding(UIMetrics.activitiesRowPadding)
        .frame(height: UIMetrics.activitiesRowGapHeight)
        .overlay(shape.strokeBorder(Night.trackerAway, style: StrokeStyle(lineWidth: UIMetrics.cardBorder, dash: UIMetrics.trackerNotLoggedDash)))
    }
}
