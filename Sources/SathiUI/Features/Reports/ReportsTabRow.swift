import SathiCore
import SwiftUI

struct ReportsTabRow: View {
    let scores: [BuddyScore]
    @Binding var selected: HabitID?

    var body: some View {
        HStack(spacing: UIMetrics.reportsTabGap) {
            tab(Copywriter.reportsAllBuddies, color: Night.text, fill: Night.navSelected, isSelected: selected == nil) {
                selected = nil
            }
            ForEach(scores) { score in
                tab(
                    Copywriter.reportsTab(score.habit, met: score.met, days: score.days),
                    color: Night.accent(score.habit),
                    fill: Night.heroFill(score.habit),
                    isSelected: selected == score.habit
                ) {
                    selected = score.habit
                }
                .disabled(score.isOff)
                .opacity(score.isOff ? UIMetrics.reportsOffOpacity : 1)
            }
            Spacer(minLength: 0)
        }
        .frame(height: UIMetrics.reportsTabHeight)
    }

    private func tab(_ title: String, color: Color, fill: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.reportsTabRadius, style: .continuous)
        return Button(action: action) {
            Text(verbatim: title)
                .font(Typography.tracker(UIMetrics.reportsTabFont, isSelected ? .heavy : .bold))
                .foregroundStyle(color)
                .lineLimit(1)
                .padding(.horizontal, UIMetrics.reportsTabPadding)
                .frame(height: UIMetrics.reportsTabHeight)
                .background(shape.fill(isSelected ? fill : Night.card))
                .overlay(shape.strokeBorder(
                    isSelected ? color : Night.border,
                    lineWidth: isSelected ? UIMetrics.reportsSelectedBorder : UIMetrics.cardBorder
                ))
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
