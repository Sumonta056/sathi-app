import Foundation

package enum TodoBoardColumns {
    package static func count(width: Double?, min: Double, gap: Double) -> Int {
        guard let width, width.isFinite, width > 0, min + gap > 0 else { return 1 }
        let n = ((width + gap) / (min + gap)).rounded(.down)
        guard n.isFinite, n >= 1 else { return 1 }
        return Int(n)
    }

    package static func place(heights: [Double], columns: Int, previous: [Int]?) -> [Int] {
        let n = max(1, columns)
        if let previous, previous.count == heights.count, previous.allSatisfy({ (0 ..< n).contains($0) }) {
            return previous
        }
        var totals = Array(repeating: 0.0, count: n)
        return heights.map { h in
            let i = totals.indices.min { totals[$0] < totals[$1] } ?? 0
            totals[i] += h
            return i
        }
    }
}
