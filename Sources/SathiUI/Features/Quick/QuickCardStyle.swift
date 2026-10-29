import SwiftUI

extension View {
    func quickCardStyle() -> some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.cardRadius, style: .continuous)
        return padding(UIMetrics.cardPadding)
            .background(shape.fill(Night.card))
            .overlay(shape.strokeBorder(Night.quickBorder, lineWidth: UIMetrics.cardBorder))
    }
}
