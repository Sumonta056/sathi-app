import SathiCore
import SwiftUI

enum TodoBoardPart: Equatable {
    case card
    case column(Int)
    case slot
}

struct TodoBoardPartKey: LayoutValueKey {
    static let defaultValue = TodoBoardPart.card
}

struct TodoBoardFixed: Equatable {
    let saved: [[String]]
    let count: Int
    let slot: TodoBoardSlot?
}

struct TodoBoardFixedKey: Equatable {
    let ids: [String]
    let saved: [[String]]
    let count: Int
    let fit: Int
}

extension TodoBoardLayout {
    func fixedFrames(_ width: CGFloat, _ subviews: Subviews, _ cache: inout Cache, real: Bool, fixed: TodoBoardFixed) -> [CGRect] {
        let parts = subviews.map { $0[TodoBoardPartKey.self] }
        var heights: [String: CGFloat] = [:]
        for (view, part) in zip(subviews, parts) where part == .card {
            heights[view[TodoBoardKey.self]] = view.sizeThatFits(ProposedViewSize(width: width, height: nil)).height
        }
        let ids = zip(subviews, parts).filter { $0.1 == .card }.map { $0.0[TodoBoardKey.self] }
        let base = baseColumns(ids, heights, fixed, &cache, real: real)
        let shown = fixed.slot.flatMap { s in
            TodoBoardColumnLayout.moved(shown: base, id: s.id, column: s.column, before: s.before, count: base.count)
        } ?? base
        let resting = stack(base, heights, width)
        let preview = stack(shown, heights, width)
        let bottom = max(resting.values.map(\.maxY).max() ?? 0, preview.values.map(\.maxY).max() ?? 0)
        return zip(subviews, parts).map { view, part in
            switch part {
            case .card:
                let id = view[TodoBoardKey.self]
                return (fixed.slot?.id == id ? resting[id] : preview[id]) ?? .zero
            case let .column(i):
                return CGRect(x: CGFloat(i) * (width + gap), y: 0, width: width, height: bottom)
            case .slot:
                return fixed.slot.flatMap { preview[$0.id] } ?? .zero
            }
        }
    }

    private func baseColumns(
        _ ids: [String], _ heights: [String: CGFloat], _ fixed: TodoBoardFixed, _ cache: inout Cache, real: Bool
    ) -> [[String]] {
        let key = TodoBoardFixedKey(ids: ids, saved: fixed.saved, count: fixed.count, fit: count)
        if real, cache.fixedKey == key { return cache.fixedColumns }
        let columns = TodoBoardColumnLayout.arranged(
            lists: ids, saved: fixed.saved, count: fixed.count, fit: count,
            heights: heights.mapValues { Double($0 + gap) }
        )
        if real {
            cache.fixedKey = key
            cache.fixedColumns = columns
        }
        return columns
    }

    private func stack(_ columns: [[String]], _ heights: [String: CGFloat], _ width: CGFloat) -> [String: CGRect] {
        var frames: [String: CGRect] = [:]
        for (c, ids) in columns.enumerated() {
            var top: CGFloat = 0
            for id in ids {
                let h = heights[id] ?? 0
                frames[id] = CGRect(x: CGFloat(c) * (width + gap), y: top, width: width, height: h)
                top += h + gap
            }
        }
        return frames
    }
}
