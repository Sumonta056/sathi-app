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
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.bubbleRadius, style: .continuous)
    }
}
