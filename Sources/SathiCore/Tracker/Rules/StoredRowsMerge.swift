import Foundation

package enum StoredRowsMerge {
    package static func merged(_ month: ActivityMonth, calendar: Calendar, keep: Set<ActivityID>) -> ActivityMonth? {
        let days = Dictionary(grouping: month.items) { calendar.startOfDay(for: $0.start) }
        var changed = false
        var items: [Activity] = []
        for dayStart in days.keys.sorted() {
            let rows = days[dayStart] ?? []
            let out = rows.contains { keep.contains($0.id) } ? rows : ActivityMerge.merged(rows)
            if out.count != rows.count { changed = true }
            items += out
        }
        return changed ? ActivityMonth(key: month.key, items: items) : nil
    }
}
