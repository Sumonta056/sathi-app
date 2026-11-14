import Foundation

package enum ActivityMerge {
    package static func canMerge(_ previous: Activity, _ next: Activity) -> Bool {
        guard previous.kind == .work, next.kind == .work,
              previous.sourceEventID == nil, next.sourceEventID == nil,
              previous.category == next.category,
              trimmed(previous.text) == trimmed(next.text) else { return false }
        let gap = next.start.timeIntervalSince(previous.end)
        return gap >= 0 && gap <= Timing.activityMergeGap
    }

    package static func joined(_ previous: Activity, _ next: Activity) -> Activity {
        var a = previous
        a.end = max(previous.end, next.end)
        if !hasEvent(a), hasEvent(next) {
            a.eventID = next.eventID
            a.calendarID = next.calendarID
        } else {
            a.calendarID = previous.calendarID ?? next.calendarID
        }
        return a
    }

    package static func hasEvent(_ a: Activity) -> Bool { !(a.eventID ?? "").isEmpty }

    private static func trimmed(_ s: String) -> String { s.trimmingCharacters(in: .whitespacesAndNewlines) }
}
