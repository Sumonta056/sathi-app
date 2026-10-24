import SwiftUI

struct GhostButton: ButtonStyle {
    let accent: Color
    var height: CGFloat = UIMetrics.ghostButtonHeight

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.chip)
            .foregroundStyle(accent)
            .padding(.horizontal, UIMetrics.ghostButtonPadding)
            .frame(height: height)
            .background(shape.fill(accent.opacity(configuration.isPressed ? UIMetrics.chipFillOpacity : 0)))
            .overlay(shape.strokeBorder(Night.fieldBorder, lineWidth: UIMetrics.chipBorder))
            .contentShape(shape)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous)
    }
}
