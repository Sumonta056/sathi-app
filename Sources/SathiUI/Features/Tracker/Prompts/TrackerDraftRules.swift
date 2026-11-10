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

enum TrackerSwitchPick {
    static func minutes(of date: Date, calendar: Calendar) -> Int {
        calendar.component(.hour, from: date) * Limits.minutesPerHour + calendar.component(.minute, from: date)
    }

    static func nearest(to minutes: Int, in times: [Date], calendar: Calendar) -> Date? {
        times.min { abs(Self.minutes(of: $0, calendar: calendar) - minutes) < abs(Self.minutes(of: $1, calendar: calendar) - minutes) }
    }
}

extension TrackerPromptState {
    func recentsShown(_ limit: Int) -> [RecentActivity] {
        Array(recents.prefix(limit))
    }
}
