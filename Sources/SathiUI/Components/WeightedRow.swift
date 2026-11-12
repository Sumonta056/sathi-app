import SwiftUI

struct WeightedRow: Layout {
    let gap: CGFloat
    let weights: [CGFloat]

    static func widths(total: CGFloat, gap: CGFloat, weights: [CGFloat]) -> [CGFloat] {
        let sum = weights.reduce(0, +)
        guard sum > 0 else { return weights.map { _ in 0 } }
        let free = max(0, total - gap * CGFloat(max(0, weights.count - 1)))
        return weights.map { free * $0 / sum }
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let total = proposal.width ?? 0
        let widths = Self.widths(total: total, gap: gap, weights: weights)
        let height = zip(subviews, widths).map { $0.sizeThatFits(ProposedViewSize(width: $1, height: proposal.height)).height }.max() ?? 0
        return CGSize(width: total, height: proposal.height ?? height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let widths = Self.widths(total: bounds.width, gap: gap, weights: weights)
        var x = bounds.minX
        for (view, width) in zip(subviews, widths) {
            view.place(at: CGPoint(x: x, y: bounds.minY), anchor: .topLeading, proposal: ProposedViewSize(width: width, height: bounds.height))
            x += width + gap
        }
    }
}
