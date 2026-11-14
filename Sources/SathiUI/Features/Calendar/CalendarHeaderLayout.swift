import SwiftUI

struct CalendarHeaderLayout: Layout {
    let gap: CGFloat

    static func rows(_ widths: [CGFloat], width: CGFloat, gap: CGFloat) -> [[Int]] {
        let all = Array(widths.indices)
        if fits(widths, all, width: width, gap: gap) { return [all] }
        guard widths.count > 2 else { return all.map { [$0] } }
        if fits(widths, [0, 1], width: width, gap: gap) { return [[0, 1], Array(all.dropFirst(2))] }
        return all.map { [$0] }
    }

    private static func fits(_ widths: [CGFloat], _ row: [Int], width: CGFloat, gap: CGFloat) -> Bool {
        row.map { widths[$0] }.reduce(0, +) + gap * CGFloat(max(row.count - 1, 0)) <= width
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let oneRow = sizes.map(\.width).reduce(0, +) + gap * CGFloat(max(sizes.count - 1, 0))
        let width = proposal.width ?? oneRow
        let rows = Self.rows(sizes.map(\.width), width: width, gap: gap)
        let heights = rows.map { row in row.map { sizes[$0].height }.max() ?? 0 }
        return CGSize(width: width, height: heights.reduce(0, +) + gap * CGFloat(max(rows.count - 1, 0)))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let controls = subviews.count - 1
        var y = bounds.minY
        for row in Self.rows(sizes.map(\.width), width: bounds.width, gap: gap) {
            let height = row.map { sizes[$0].height }.max() ?? 0
            let midY = y + height / 2
            guard let first = row.first, let last = row.last else { continue }
            subviews[first].place(at: CGPoint(x: bounds.minX, y: midY), anchor: .leading, proposal: .unspecified)
            var right = bounds.maxX
            if last != first, last == controls {
                subviews[last].place(at: CGPoint(x: bounds.maxX, y: midY), anchor: .trailing, proposal: .unspecified)
                right -= sizes[last].width + gap
            }
            let left = bounds.minX + sizes[first].width + gap
            for index in row where index != first && !(index == last && last == controls) {
                subviews[index].place(at: CGPoint(x: (left + right) / 2, y: midY), anchor: .center, proposal: .unspecified)
            }
            y += height + gap
        }
    }
}
