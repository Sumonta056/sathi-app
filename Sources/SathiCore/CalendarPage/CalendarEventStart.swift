import Foundation

package enum CalendarEventStart {
    private static let lead = TimeInterval(Limits.calendarHostLeadMinutes) * Timing.minute

    package static func allows(_ e: CalendarEventInfo, now: Date?, trackerOn: Bool) -> Bool {
        guard trackerOn, let now else { return false }
        return e.start.addingTimeInterval(-lead) <= now && now < e.end
    }
}
