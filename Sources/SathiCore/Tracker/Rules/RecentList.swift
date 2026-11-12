import Foundation

package enum RecentList {
    package static func recents(_ items: [Activity], max limit: Int = Limits.recentMax) -> [RecentActivity] {
        var seen: Set<Key> = []
        var list: [RecentActivity] = []
        for item in items.sorted(by: { $0.end > $1.end }) where counts(item) {
            let key = Key(text: item.text, category: item.category)
            guard seen.insert(key).inserted else { continue }
            list.append(RecentActivity(text: item.text, category: item.category, length: item.length))
            if list.count == limit { break }
        }
        return list
    }

    private struct Key: Hashable {
        var text: String
        var category: String?
    }

    private static func counts(_ item: Activity) -> Bool {
        switch item.kind {
        case .work, .event: return true
        case .away, .timeBlock, .buddy: return false
        }
    }
}
