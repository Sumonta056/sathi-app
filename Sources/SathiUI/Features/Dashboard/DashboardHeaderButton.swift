import SathiCore
import SwiftUI

struct DashboardHeaderButton: ButtonStyle {
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
