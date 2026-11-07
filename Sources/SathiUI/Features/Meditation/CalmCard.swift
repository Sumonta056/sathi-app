import SathiCore
import SwiftUI

struct CalmCard: ViewModifier {
    var alert = false
    var top = UIMetrics.calmPadding
    var bottom = UIMetrics.calmPadding

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, UIMetrics.calmPadding)
            .padding(.top, top)
            .padding(.bottom, bottom)
            .frame(width: UIMetrics.calmCardWidth)
            .background(shape.fill(Night.calmGround))
            .overlay(shape.strokeBorder(
                alert ? Night.calm : Night.heroBorder(.meditation),
                lineWidth: alert ? UIMetrics.bubbleAlertBorder : UIMetrics.bubbleBorder
            ))
            .padding(UIMetrics.bubbleShadowPadding)
            .environment(\.colorScheme, .dark)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.calmRadius, style: .continuous)
    }
}
