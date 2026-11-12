import SwiftUI

struct PageHeaderLayout: Layout {
    let gap: CGFloat

    static func fitsOneRow(width: CGFloat, title: CGFloat, controls: CGFloat, gap: CGFloat) -> Bool {
        title + gap + controls <= width
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard subviews.count == 2 else { return .zero }
        let title = subviews[0].sizeThatFits(.unspecified)
        let controls = subviews[1].sizeThatFits(.unspecified)
        let oneRow = title.width + gap + controls.width
        let width = proposal.width ?? oneRow
        if Self.fitsOneRow(width: width, title: title.width, controls: controls.width, gap: gap) {
            return CGSize(width: width, height: max(title.height, controls.height))
        }
        return CGSize(width: width, height: title.height + gap + controls.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 2 else { return }
        let title = subviews[0].sizeThatFits(.unspecified)
        let controls = subviews[1].sizeThatFits(.unspecified)
        if Self.fitsOneRow(width: bounds.width, title: title.width, controls: controls.width, gap: gap) {
            subviews[0].place(at: CGPoint(x: bounds.minX, y: bounds.midY), anchor: .leading, proposal: .unspecified)
            subviews[1].place(at: CGPoint(x: bounds.maxX, y: bounds.midY), anchor: .trailing, proposal: .unspecified)
        } else {
            subviews[0].place(at: CGPoint(x: bounds.minX, y: bounds.minY), anchor: .topLeading, proposal: .unspecified)
            subviews[1].place(at: CGPoint(x: bounds.minX, y: bounds.minY + title.height + gap), anchor: .topLeading, proposal: .unspecified)
        }
    }
}
