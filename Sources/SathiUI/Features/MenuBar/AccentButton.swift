import SwiftUI

struct AccentButton: ButtonStyle {
    let accent: Color
    var height: CGFloat = UIMetrics.actionHeight
    var radius: CGFloat = UIMetrics.buttonRadius
    var text: Color = Night.onAccent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.chip)
            .foregroundStyle(text)
            .padding(.horizontal, UIMetrics.chipPadding)
            .frame(height: height)
            .background(shape.fill(accent))
            .opacity(configuration.isPressed ? UIMetrics.pressedOpacity : 1)
            .contentShape(shape)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }
}
