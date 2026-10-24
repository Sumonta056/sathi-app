import SwiftUI

struct WaterCard: ViewModifier {
    var alert = false

    func body(content: Content) -> some View {
        content
            .frame(width: UIMetrics.waterBubbleWidth)
            .background(shape.fill(Night.bg))
            .overlay(shape.strokeBorder(
                alert ? Night.water : Night.heroBorder(.water),
                lineWidth: alert ? UIMetrics.bubbleAlertBorder : UIMetrics.bubbleBorder
            ))
            .shadow(
                color: Color.black.opacity(UIMetrics.bubbleShadowOpacity),
                radius: UIMetrics.bubbleShadowRadius,
                x: 0,
                y: UIMetrics.bubbleShadowY
            )
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.bubbleRadius, style: .continuous)
    }
}
