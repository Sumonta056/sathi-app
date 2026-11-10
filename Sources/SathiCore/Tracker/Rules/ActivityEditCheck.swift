import Foundation

package enum ActivityEditCheck {
    package static func problem(_ edit: ActivityEdit, others: [DateInterval]) -> ActivityEditResult? {
        guard ActivityText.clean(edit.text) != nil else { return .emptyText }
        guard edit.end.timeIntervalSince(edit.start) >= Timing.activityMinimum else { return .tooShort }
        let span = DateInterval(start: edit.start, end: edit.end)
        let hits = others.contains { $0.start < span.end && span.start < $0.end }
        return hits ? .overlap : nil
    }
}
