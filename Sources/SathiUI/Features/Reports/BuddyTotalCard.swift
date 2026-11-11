import SathiCore
import SwiftUI

struct BuddyTotalCard: View {
    let total: BuddyRangeTotal
    let kind: ReportRange
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        let accent = Night.accent(total.habit)
        Button(action: action) {
            VStack(alignment: .leading, spacing: UIMetrics.textSpacing) {
                Text(verbatim: Copywriter.reportsBuddyLabel(total.habit))
                    .font(Typography.rowLabel)
                    .foregroundStyle(accent)
                Text(verbatim: Copywriter.reportsAmount(total.habit, total.total))
                    .font(Typography.bigNumber)
                    .foregroundStyle(Night.text)
                    .lineLimit(1)
                    .minimumScaleFactor(UIMetrics.trackerTileMinScale)
                if total.isOff {
                    note(Copywriter.reportsOff)
                } else {
                    RangeChangeText(change: total.change, text: changeText)
                    note(Copywriter.reportsGoalMet(total.daysMet, of: total.daysCounted))
                }
            }
            .padding(UIMetrics.tilePadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(shape.fill(Night.card))
            .overlay(shape.strokeBorder(
                isSelected ? accent : Night.border,
                lineWidth: isSelected ? UIMetrics.tileSelectedBorder : UIMetrics.cardBorder
            ))
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .opacity(total.isOff ? UIMetrics.reportsOffOpacity : 1)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var changeText: String {
        let habit = total.habit
        return Copywriter.rangeChange(total.change, kind: kind) { Copywriter.reportsAmount(habit, $0) }
    }

    private func note(_ text: String) -> some View {
        Text(verbatim: text)
            .font(Typography.hint)
            .foregroundStyle(Night.muted)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.cardRadius, style: .continuous)
    }
}
