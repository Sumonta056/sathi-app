import SathiCore
import SwiftUI

struct TodayHeaderButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.todayButtonRadius, style: .continuous)
        return configuration.label
            .font(Typography.tracker(UIMetrics.todayButtonFont, .semibold))
            .foregroundStyle(Night.text)
            .padding(.horizontal, UIMetrics.todayButtonPadding)
            .frame(height: UIMetrics.todayButtonHeight)
            .background(shape.fill(Night.card))
            .overlay(shape.stroke(Night.border))
            .opacity(configuration.isPressed ? UIMetrics.pressedOpacity : 1)
            .contentShape(shape)
    }
}

struct TodayHeader: View {
    let e: Engine
    let dateLine: String
    let greeting: String

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: UIMetrics.todayHeaderGap) {
                Text(verbatim: dateLine)
                    .font(Typography.tracker(UIMetrics.todayDateFont, .semibold))
                    .tracking(UIMetrics.todayDateTracking)
                    .foregroundStyle(Night.label)
                Text(verbatim: greeting)
                    .font(Typography.tracker(UIMetrics.todayTitleFont, .heavy))
                    .foregroundStyle(Night.text)
            }
            Spacer(minLength: 0)
            HStack(spacing: UIMetrics.todayButtonGap) {
                Button { e.openQuickAdd() } label: { Text(verbatim: Copywriter.todayQuickReminder) }
                    .buttonStyle(TodayHeaderButton())
                BreakMenu()
            }
        }
    }
}
