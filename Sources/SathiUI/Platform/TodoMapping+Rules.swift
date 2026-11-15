import Foundation

struct TodoSourceInfo: Equatable {
    let id: String
    let isCalDAV: Bool
    let hasReminderLists: Bool
}

extension TodoMapping {
    static func iCloudSourceID(defaultSourceID: String?, sources: [TodoSourceInfo]) -> String? {
        if let id = defaultSourceID, sources.contains(where: { $0.id == id && $0.isCalDAV }) { return id }
        let withLists = sources.filter { $0.isCalDAV && $0.hasReminderLists }
        if withLists.count == 1 { return withLists[0].id }
        return withLists.first?.id
    }

    static func alarmDates(oldDue: Date?, newDue: Date?, alarms: [Date]) -> [Date?] {
        alarms.map { at in
            guard let oldDue, abs(at.timeIntervalSince(oldDue)) < 1 else { return at }
            return newDue
        }
    }
}
