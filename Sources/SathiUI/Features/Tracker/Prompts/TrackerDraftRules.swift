import SathiCore
import SwiftUI

extension ActivityDraft {
    var committed: ActivityDraft? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        var copy = self
        copy.text = String(trimmed.prefix(Limits.activityTextMax))
        return copy
    }

    func filled(from recent: RecentActivity) -> ActivityDraft {
        var copy = self
        copy.text = recent.text
        copy.category = recent.category
        copy.sourceEventID = nil
        return copy
    }

    func filled(from event: CalendarEventInfo) -> ActivityDraft {
        var copy = self
        copy.text = event.title
        copy.sourceEventID = event.id
        return copy
    }

    func with(length: ActivityLength) -> ActivityDraft {
        var copy = self
        copy.length = length
        if length == .open { copy.quiet = false }
        return copy
    }
}
