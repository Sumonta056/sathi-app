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
        let sorted = filter { !$0.text.isEmpty }.sorted {
            $0.fireDate == $1.fireDate ? $0.createdAt < $1.createdAt : $0.fireDate < $1.fireDate
        }
        return Array(sorted.prefix(Limits.quickMax))
    }
}
