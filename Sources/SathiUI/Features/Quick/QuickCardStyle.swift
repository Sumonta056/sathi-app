import SwiftUI

extension View {
    func quickCardStyle() -> some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.cardRadius, style: .continuous)
        return padding(UIMetrics.cardPadding)
            .background(shape.fill(Night.card))
            .overlay(shape.strokeBorder(Night.quickBorder, lineWidth: UIMetrics.cardBorder))
    }
}

struct QuickTextLimit: ViewModifier {
    @Binding var text: String
    let limit: Int

    func body(content: Content) -> some View {
        content.onChange(of: text) { value in
            if value.count > limit { text = String(value.prefix(limit)) }
        }
    }
}
