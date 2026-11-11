import SathiCore
import SwiftUI

struct TrackerCard: ViewModifier {
    let compact: Bool
    let width: CGFloat
    var spacing: CGFloat?

    func body(content: Content) -> some View {
        let size = TrackerSize.of(compact: compact)
        let shape = RoundedRectangle(cornerRadius: size.cardRadius, style: .continuous)
        return content
            .padding(size.cardPadding)
            .frame(width: width)
            .background(shape.fill(Night.card))
            .overlay(shape.strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
            .padding(compact ? UIMetrics.bubbleShadowPadding : 0)
            .environment(\.colorScheme, .dark)
    }
}

extension View {
    func trackerField(compact: Bool = true) -> some View {
        let size = TrackerSize.of(compact: compact)
        let shape = RoundedRectangle(cornerRadius: size.fieldRadius, style: .continuous)
        return padding(.horizontal, size.fieldPadding)
            .frame(height: size.fieldHeight)
            .background(shape.fill(Night.bg))
            .overlay(shape.strokeBorder(Night.tracker, lineWidth: UIMetrics.trackerFieldBorder))
    }

    func trackerCornerCard() -> some View {
        modifier(TrackerCard(compact: true, width: UIMetrics.trackerCornerCard))
    }

    func trackerCenterCard(width: CGFloat = UIMetrics.trackerCenterCard) -> some View {
        modifier(TrackerCard(compact: false, width: width))
    }
}
