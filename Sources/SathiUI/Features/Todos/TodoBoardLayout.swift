import SathiCore
import SwiftUI

struct TodoBoardKey: LayoutValueKey {
    static let defaultValue = ""
}

struct TodoBoardLayout: Layout {
    let columns: Int
    let gap: CGFloat

    struct Cache {
        var ids: [String] = []
        var columns = 0
        var assign: [Int] = []
    }

    func makeCache(subviews _: Subviews) -> Cache { Cache() }

    func updateCache(_: inout Cache, subviews _: Subviews) {}

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        let width = columnWidth(proposal.width)
        let frames = arrange(width, subviews, &cache)
        let bottom = frames.map(\.maxY).max() ?? 0
        return CGSize(width: total(width), height: bottom)
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        let width = columnWidth(bounds.width)
        for (view, frame) in zip(subviews, arrange(width, subviews, &cache)) {
            view.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(width: frame.width, height: frame.height)
            )
        }
    }

    private var count: Int { max(1, columns) }

    private func columnWidth(_ proposed: CGFloat?) -> CGFloat {
        guard let proposed, proposed.isFinite, proposed > 0 else { return UIMetrics.todoBoardMinWidth }
        return max(0, (proposed - gap * CGFloat(count - 1)) / CGFloat(count))
    }

    private func total(_ width: CGFloat) -> CGFloat {
        width * CGFloat(count) + gap * CGFloat(count - 1)
    }

    private func arrange(_ width: CGFloat, _ subviews: Subviews, _ cache: inout Cache) -> [CGRect] {
        let heights = subviews.map { $0.sizeThatFits(ProposedViewSize(width: width, height: nil)).height }
        let ids = subviews.map { $0[TodoBoardKey.self] }
        let same = cache.ids == ids && cache.columns == count
        let assign = TodoBoardColumns.place(
            heights: heights.map { Double($0 + gap) },
            columns: count,
            previous: same ? cache.assign : nil
        )
        cache = Cache(ids: ids, columns: count, assign: assign)
        var tops = Array(repeating: CGFloat(0), count: count)
        return zip(heights, assign).map { h, column in
            let rect = CGRect(x: CGFloat(column) * (width + gap), y: tops[column], width: width, height: h)
            tops[column] += h + gap
            return rect
        }
    }
}
