import SwiftUI

struct AccentButton: ButtonStyle {
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.chip)
            .foregroundStyle(Night.onAccent)
            .padding(.horizontal, UIMetrics.chipPadding)
            .frame(height: UIMetrics.actionHeight)
            .background(shape.fill(accent))
            .opacity(configuration.isPressed ? UIMetrics.pressedOpacity : 1)
            .contentShape(shape)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous)
    }
}
