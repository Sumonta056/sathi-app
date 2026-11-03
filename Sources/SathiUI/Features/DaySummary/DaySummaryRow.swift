import SathiCore
import SwiftUI

struct DaySummaryRowView: View {
    let row: DaySummaryRow

    var body: some View {
        HStack(alignment: .top, spacing: UIMetrics.summaryRowSpacing) {
            StaticBuddy(habit: row.id, size: UIMetrics.summaryBuddySize)
            VStack(alignment: .leading, spacing: UIMetrics.summaryRowTextSpacing) {
                HStack(spacing: UIMetrics.cornerButtonSpacing) {
                    Text(eyebrow)
                        .font(Typography.eyebrow)
                        .foregroundStyle(Night.accent(row.id))
                    Spacer(minLength: 0)
                    trailing
                }
                ProgressBar(value: fraction, tint: Night.accent(row.id), height: UIMetrics.summaryBarHeight, track: Night.divider)
                Text("\(max(row.streak, 1))-day streak")
                    .font(Typography.pillHint)
                    .foregroundStyle(Night.spark)
                    .opacity(row.streak > 0 ? 1 : 0)
                    .accessibilityHidden(row.streak == 0)
            }
        }
        .opacity(row.status == .off ? UIMetrics.summaryDimmedOpacity : 1)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var trailing: some View {
        switch row.status {
        case .off: label("Off")
        case .dayOff: label("Day off")
        case let .progress(done, goal):
            let goal = Copywriter.daySummaryValue(row.id, done: done, goal: goal)
            HStack(spacing: UIMetrics.summaryRowTextSpacing) {
                Text(goal.done).font(Typography.chip).foregroundStyle(Night.text)
                Text(goal.rest).font(Typography.pillHint).foregroundStyle(Night.muted)
                if row.status.isMet {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: UIMetrics.summaryCheckSize))
                        .foregroundStyle(Night.sprout)
                        .accessibilityLabel("Goal met")
                }
            }
        }
    }

    private func label(_ text: String) -> some View {
        Text(text).font(Typography.pillHint).foregroundStyle(Night.muted)
    }

    private var fraction: Double {
        guard case let .progress(done, goal) = row.status, goal > 0 else { return 0 }
        return done / goal
    }

    private var eyebrow: String {
        switch row.id {
        case .water: return "FOTA · WATER"
        case .reading: return "BOI · READING"
        case .meditation: return "SHANTI · MEDITATION"
        case .gym: return "SHOKTI · GYM"
        }
    }
}
