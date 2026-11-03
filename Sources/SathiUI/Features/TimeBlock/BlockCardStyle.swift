import SwiftUI

extension View {
    func blockCardStyle(padding inset: EdgeInsets = UIMetrics.blockCardPadding) -> some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.cardRadius, style: .continuous)
        return padding(inset)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(shape.fill(Night.blockFill))
            .overlay(shape.strokeBorder(Night.blockBorder, lineWidth: UIMetrics.cardBorder))
    }

    func blockFieldStyle(height: CGFloat = UIMetrics.blockActionHeight) -> some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous)
        return padding(.horizontal, UIMetrics.blockMenuPadding)
            .frame(height: height)
            .background(shape.fill(Night.bg))
            .overlay(shape.strokeBorder(Night.fieldBorder, lineWidth: UIMetrics.cardBorder))
            .contentShape(shape)
    }
}
