import SwiftUI

struct CornerCard: ViewModifier {
    var width = UIMetrics.cornerWidth
    var alert = false

    func body(content: Content) -> some View {
        content
            .padding(UIMetrics.cornerPadding)
            .frame(width: width)
            .background(shape.fill(Night.card))
            .overlay(shape.strokeBorder(
                alert ? Night.reading : Night.heroBorder(.reading),
                lineWidth: alert ? UIMetrics.bubbleAlertBorder : UIMetrics.bubbleBorder
            ))
            .modifier(CornerShadow())
            .padding(UIMetrics.bubbleShadowPadding)
            .environment(\.colorScheme, .dark)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.cornerRadius, style: .continuous)
    }
}

struct CornerShadow: ViewModifier {
    func body(content: Content) -> some View {
        content.shadow(
            color: Color.black.opacity(UIMetrics.cornerShadowOpacity),
            radius: UIMetrics.cornerShadowRadius,
            x: 0,
            y: UIMetrics.cornerShadowY
        )
    }
}

struct CornerCloseButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: UIMetrics.closeIconSize, weight: .bold))
                .foregroundStyle(Night.muted)
                .frame(width: UIMetrics.closeButtonSize, height: UIMetrics.closeButtonSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
