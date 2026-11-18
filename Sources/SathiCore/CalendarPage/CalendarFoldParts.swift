import Foundation

enum CalendarFoldParts {
    static func open(_ span: Range<Int>, rows: [CalendarGridRow]) -> [Range<Int>] {
        var parts: [Range<Int>] = []
        var from = span.lowerBound
        for strip in rows where strip.isFold && strip.endMinute > span.lowerBound && strip.startMinute < span.upperBound {
            if strip.startMinute > from { parts.append(from ..< strip.startMinute) }
            from = max(from, strip.endMinute)
        }
        if from < span.upperBound { parts.append(from ..< span.upperBound) }
        return parts
    }
}
