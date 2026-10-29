import Foundation

package struct QuickReminder: Codable, Equatable, Identifiable, Sendable {
    package var id: UUID
    package var text: String
    package var due: Date
    package var createdAt: Date
    package var snoozedUntil: Date?
    package var snoozes: Int

    package var fireDate: Date { snoozedUntil ?? due }

    package init(id: UUID = UUID(), text: String, due: Date, createdAt: Date) {
        self.id = id
        self.text = text
        self.due = due
        self.createdAt = createdAt
        snoozedUntil = nil
        snoozes = 0
    }
}

extension QuickReminder {
    package init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        text = try QuickText.clean(c.decode(String.self, forKey: .text))
        due = try c.decode(Date.self, forKey: .due).wholeSecond
        createdAt = try c.decode(Date.self, forKey: .createdAt).wholeSecond
        snoozedUntil = c.lenient(.snoozedUntil, or: Date?.none)?.wholeSecond
        snoozes = max(0, c.lenient(.snoozes, or: 0))
    }
}

extension [QuickReminder] {
    package func kept() -> [QuickReminder] {
        var seen = Set<UUID>()
        let sorted = filter { !$0.text.isEmpty && seen.insert($0.id).inserted }.sorted {
            if $0.fireDate != $1.fireDate { return $0.fireDate < $1.fireDate }
            if $0.createdAt != $1.createdAt { return $0.createdAt < $1.createdAt }
            return $0.id.uuidString < $1.id.uuidString
        }
        return Array(sorted.prefix(Limits.quickMax))
    }
}
