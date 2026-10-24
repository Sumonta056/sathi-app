import SathiCore
import SwiftUI

struct CalmCard: ViewModifier {
    var alert = false

    func body(content: Content) -> some View {
        content
            .padding(UIMetrics.calmPadding)
            .frame(width: UIMetrics.calmCardWidth)
            .background(shape.fill(Night.calmGround))
            .overlay(shape.strokeBorder(
                alert ? Night.calm : Night.heroBorder(.meditation),
                lineWidth: alert ? UIMetrics.bubbleAlertBorder : UIMetrics.bubbleBorder
            ))
            .shadow(
                color: Color.black.opacity(UIMetrics.bubbleShadowOpacity),
                radius: UIMetrics.bubbleShadowRadius,
                x: 0,
                y: UIMetrics.bubbleShadowY
            )
            .padding(UIMetrics.bubbleShadowPadding)
            .environment(\.colorScheme, .dark)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.calmRadius, style: .continuous)
    }
}
