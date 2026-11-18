import Foundation

package enum CalendarNightFold {
    package static func rows(busy: [Range<Int>], rowMinutes: Int, metrics: CalendarLayoutMetrics) -> [CalendarGridRow] {
        let step = max(1, rowMinutes)
        let starts = Array(stride(from: 0, to: Limits.minutesPerDay, by: step))
        let quiet = starts.map { s in metrics.foldsNights && !busy.contains { crosses($0, s, s + step) } }
        var rows: [CalendarGridRow] = []
        var i = 0
        while i < starts.count {
            var j = i
            while j < starts.count, quiet[j] {
                j += 1
            }
            if j - i >= Limits.calendarFoldMinRows {
                rows.append(row(starts[i], end(of: starts[j - 1], step), height: metrics.foldHeight, fold: true, after: rows))
                i = j
            } else {
                let (s, e) = (starts[i], end(of: starts[i], step))
                rows.append(row(s, e, height: Double(e - s) * metrics.pointsPerMinute, fold: false, after: rows))
                i += 1
            }
        }
        return rows
    }

    private static func crosses(_ span: Range<Int>, _ from: Int, _ to: Int) -> Bool {
        span.isEmpty ? from <= span.lowerBound && span.lowerBound < to : span.lowerBound < to && span.upperBound > from
    }

    private static func end(of start: Int, _ step: Int) -> Int {
        min(start + step, Limits.minutesPerDay)
    }

    private static func row(_ start: Int, _ end: Int, height: Double, fold: Bool, after rows: [CalendarGridRow]) -> CalendarGridRow {
        CalendarGridRow(startMinute: start, endMinute: end, top: rows.last?.bottom ?? 0, height: height, isFold: fold)
    }
}
