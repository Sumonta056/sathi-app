import Foundation

package enum CalendarDisplayJoin {
    package static func groups(_ activities: [Activity]) -> [[Activity]] {
        var result: [[Activity]] = []
        for row in activities.sorted(by: { $0.start < $1.start }) {
            if let last = result.last?.last, joins(last, row) {
                result[result.count - 1].append(row)
            } else {
                result.append([row])
            }
        }
        return result
    }

    private static func joins(_ a: Activity, _ b: Activity) -> Bool {
        let gap = b.start.timeIntervalSince(a.end)
        return a.kind == b.kind
            && a.kind != .away
            && a.category == b.category
            && a.text.trimmingCharacters(in: .whitespacesAndNewlines) == b.text.trimmingCharacters(in: .whitespacesAndNewlines)
            && gap >= 0
            && gap <= Limits.calendarDisplayJoinGap
    }
}
