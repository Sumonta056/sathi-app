import Foundation

extension TodoBoardColumnLayout {
    package static func arranged(
        lists: [String],
        saved: [[String]],
        count: Int,
        fit: Int,
        heights: [String: Double]
    ) -> [[String]] {
        let r = assign(lists: lists, saved: saved, count: count, fit: fit)
        var columns = r.columns
        var totals = columns.map { $0.reduce(0.0) { $0 + (heights[$1] ?? 0) } }
        for id in r.unplaced {
            let i = totals.indices.min { totals[$0] < totals[$1] } ?? 0
            columns[i].append(id)
            totals[i] += heights[id] ?? 0
        }
        return columns
    }

    package static func kept(_ next: [[String]], saved: [[String]], known: Set<String>) -> [[String]] {
        var columns = next
        let placed = Set(next.flatMap { $0 })
        for (c, ids) in saved.enumerated() where columns.indices.contains(c) {
            for (i, id) in ids.enumerated() where known.contains(id) && !placed.contains(id) {
                let after = ids[(i + 1)...].first { columns[c].contains($0) && placed.contains($0) }
                let at = after.flatMap { columns[c].firstIndex(of: $0) } ?? columns[c].count
                columns[c].insert(id, at: at)
            }
        }
        return columns
    }
}
