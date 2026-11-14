import Foundation

enum StoredRowsMerge {
    static func days(_ month: ActivityMonth, calendar: Calendar) -> [[Activity]] {
        let days = Dictionary(grouping: month.items) { calendar.startOfDay(for: $0.start) }
        return days.keys.sorted().map { (days[$0] ?? []).sorted { $0.start < $1.start } }
    }

    static func canMerge(_ rows: [Activity]) -> Bool {
        zip(rows, rows.dropFirst()).contains { ActivityMerge.canMerge($0, $1) }
    }
}
