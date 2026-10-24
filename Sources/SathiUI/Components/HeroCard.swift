import SathiCore
import SwiftUI

struct HeroCard<Buddy: View>: View {
    let habit: HabitID
    let eyebrow: String
    let title: String
    let hint: String
    @Binding var isOn: Bool
    let switchLabel: String
    @ViewBuilder let buddy: () -> Buddy

    var body: some View {
        HStack(spacing: UIMetrics.heroSpacing) {
            buddy()
            VStack(alignment: .leading, spacing: UIMetrics.textSpacing) {
                Text(verbatim: eyebrow)
                    .font(Typography.eyebrow)
                    .tracking(UIMetrics.labelTracking)
                    .foregroundStyle(Night.accent(habit))
                Text(verbatim: title)
                    .font(Typography.heroTitle)
                    .foregroundStyle(Night.text)
                Text(verbatim: hint)
                    .font(Typography.hint)
                    .foregroundStyle(Night.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            BuddySwitch(isOn: $isOn, accent: Night.accent(habit), label: switchLabel)
        }
        .padding(UIMetrics.heroPadding)
        .background(shape.fill(Night.heroFill(habit)))
        .overlay(shape.strokeBorder(Night.heroBorder(habit), lineWidth: UIMetrics.cardBorder))
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.cardRadius, style: .continuous)
    }
}
