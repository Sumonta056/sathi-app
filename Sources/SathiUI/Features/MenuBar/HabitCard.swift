import SathiCore
import SwiftUI

struct HabitCard: View {
    @EnvironmentObject var e: Engine
    let id: HabitID

    var body: some View {
        let goal = e.goalText(id)
        let progress = e.progress(id)
        HStack(spacing: UIMetrics.buddyCardSpacing) {
            ProgressRing(progress: progress, accent: Night.accent(id))
                .accessibilityLabel("\(id.name) progress")
                .accessibilityValue(ProgressRing.percent(progress))
                .overlay(StaticBuddy(habit: id, size: UIMetrics.ringBuddySize))
            VStack(alignment: .leading, spacing: UIMetrics.textSpacing) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: UIMetrics.chipSpacing) { title; pill }
                    VStack(alignment: .leading, spacing: UIMetrics.textSpacing) { title; pill }
                }
                HStack(spacing: UIMetrics.textSpacing) {
                    Text(goal.done)
                        .font(Typography.hint.bold())
                        .foregroundStyle(Night.text)
                    Text(goal.rest)
                        .font(Typography.hint)
                        .foregroundStyle(Night.muted)
                }
            }
            Spacer(minLength: 0)
            Button(actionTitle) { act() }
                .buttonStyle(AccentButton(accent: Night.accent(id)))
        }
        .padding(UIMetrics.cardPadding)
        .background(shape.fill(Night.card))
        .overlay(shape.strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
    }

    private var title: some View {
        Text(id.name)
            .font(Typography.cardTitle)
            .foregroundStyle(Night.text)
            .lineLimit(1)
            .fixedSize()
    }

    private var pill: some View {
        Text(e.pill(id))
            .font(Typography.pill)
            .monospacedDigit()
            .foregroundStyle(Night.accent(id))
            .lineLimit(1)
            .fixedSize()
            .padding(UIMetrics.pillPadding)
            .background(Capsule().fill(Night.heroFill(id)))
    }

    private var actionTitle: String {
        switch id {
        case .water: return "+1 glass"
        case .reading: return "Read now"
        case .meditation: return "Breathe"
        }
    }

    private func act() {
        MenuBarWindow.close()
        switch id {
        case .water: e.logWater(1)
        case .reading: e.startReading()
        case .meditation: e.startMeditation()
        }
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.cardRadius, style: .continuous)
    }
}
