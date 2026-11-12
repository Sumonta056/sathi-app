import Foundation

package struct ActivityTextTotal: Equatable, Sendable {
    package var text: String
    package var category: String?
    package var seconds: TimeInterval
}

package enum ActivityTextTotals {
    package static func grouped(_ segments: [ActivitySegment]) -> [ActivityTextTotal] {
        var order: [String] = []
        var sums: [String: ActivityTextTotal] = [:]
        for s in segments where s.kind == .work {
            guard let a = s.activity else { continue }
            let key = a.text + "\u{0}" + (a.category ?? "")
            if sums[key] == nil {
                order.append(key)
                sums[key] = ActivityTextTotal(text: a.text, category: a.category, seconds: 0)
            }
            sums[key]?.seconds += s.length
        }
        let rows = order.compactMap { sums[$0] }
        return rows.sorted { ($1.seconds, $0.text) < ($0.seconds, $1.text) }
    }
}
