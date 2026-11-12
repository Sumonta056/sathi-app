import SathiCore
import SwiftUI

struct ReportsScoreCard: View {
    let overview: ReportsOverview

    var body: some View {
        let score = overview.score
        HStack(spacing: UIMetrics.reportsScoreGap) {
            ReportsRing(
                fraction: ReportsRing<EmptyView>.fraction(score.met, of: score.possible),
                color: Night.sprout,
                size: UIMetrics.reportsRingSize,
                line: UIMetrics.reportsRingLine
            ) {
                VStack(spacing: 0) {
                    Text(verbatim: "\(score.met)")
                        .font(Typography.tracker(UIMetrics.reportsRingNumberFont, .heavy))
                        .foregroundStyle(Night.text)
                    Text(verbatim: Copywriter.reportsGoalsOf(score.possible))
                        .font(Typography.tracker(UIMetrics.reportsRingCaptionFont, .semibold))
                        .foregroundStyle(Night.muted)
                }
            }
            VStack(alignment: .leading, spacing: UIMetrics.reportsScoreLineGap) {
                Text(verbatim: score.label)
                    .font(Typography.tracker(UIMetrics.reportsScoreLabelFont, .bold))
                    .foregroundStyle(Night.muted)
                Text(verbatim: score.headline)
                    .font(Typography.tracker(UIMetrics.reportsHeadlineFont, .heavy))
                    .foregroundStyle(Night.text)
                    .fixedSize(horizontal: false, vertical: true)
                Text(verbatim: score.changeText)
                    .font(Typography.tracker(UIMetrics.reportsChangeFont, .semibold))
                    .foregroundStyle(score.isUp ? Night.sprout : Night.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: UIMetrics.reportsSmallRingGap) {
                ForEach(overview.scores) { buddy in
                    smallRing(buddy)
                }
            }
        }
        .padding(UIMetrics.reportsScorePadding)
        .background(shape.fill(Night.card))
        .overlay(shape.strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
    }

    private func smallRing(_ buddy: BuddyScore) -> some View {
        let color = Night.accent(buddy.habit)
        return VStack(spacing: UIMetrics.reportsSmallRingLabelGap) {
            ReportsRing(
                fraction: ReportsRing<EmptyView>.fraction(buddy.met, of: buddy.days),
                color: color,
                size: UIMetrics.reportsSmallRingSize,
                line: UIMetrics.reportsSmallRingLine
            ) {
                Text(verbatim: Copywriter.reportsRingText(buddy.met, days: buddy.days))
                    .font(Typography.tracker(UIMetrics.reportsSmallRingFont, .heavy))
                    .foregroundStyle(Night.text)
            }
            Text(verbatim: buddy.habit.buddy)
                .font(Typography.tracker(UIMetrics.reportsRingCaptionFont, .bold))
                .foregroundStyle(color)
        }
        .opacity(buddy.isOff ? UIMetrics.reportsOffOpacity : 1)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.cardRadius, style: .continuous)
    }
}
