import Foundation

package enum TodoBoardColumnLayout {
    package static func fit(width: Double, count: Int, min: Double, gap: Double) -> Int {
        let most = Swift.max(1, count)
        guard width.isFinite, width > 0, min + gap > 0 else { return 1 }
        let n = ((width + gap) / (min + gap)).rounded(.down)
        guard n.isFinite, n >= 1 else { return 1 }
        return Swift.min(most, Int(n))
    }

    package static func assign(
        lists: [String],
        saved: [[String]],
        count: Int,
        fit: Int
    ) -> (columns: [[String]], unplaced: [String]) {
        let known = Set(lists)
        let kept = Swift.max(1, Swift.min(fit, count))
        var columns: [[String]] = []
        var placed = Set<String>()
        for index in 0 ..< kept {
            let ids = index < saved.count ? saved[index].filter { known.contains($0) && placed.insert($0).inserted } : []
            columns.append(ids)
        }
        let folded = saved.dropFirst(kept).flatMap { $0 }.filter { known.contains($0) && placed.insert($0).inserted }
        let fresh = lists.filter { placed.insert($0).inserted }
        return (columns, folded + fresh)
    }

    package static func moved(
        shown: [[String]],
        id: String,
        column: Int,
        before: String?,
        count: Int
    ) -> [[String]]? {
        guard shown.indices.contains(column), shown.count == count else { return nil }
        var columns = shown.map { $0.filter { $0 != id } }
        if let before {
            guard let at = columns[column].firstIndex(of: before) else { return nil }
            columns[column].insert(id, at: at)
        } else {
            columns[column].append(id)
        }
        return columns
    }
}
