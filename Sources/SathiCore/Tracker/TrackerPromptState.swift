import Foundation

package struct TrackerPromptState {
    package var kind: PromptKind
    package var shownAt: Date
    package var now: Date
    package var draft: ActivityDraft
    package var running: RunningActivity?
    package var lastActivity: ActivityDraft?
    package var resume: ActivityDraft?
    package var recents: [RecentActivity] = []
    package var categories: [ActivityCategory] = []
    package var calendars: [CalendarChoice] = []
    package var defaultCalendarID: String?
    package var calendarAccess: CalendarAccess = .allowed
    package var switchTimes: [Date] = []
    package var waitedMinutes: Int?
    package var away: AwaySpan?
    package var loggedWhileAway: [Activity] = []
    package var runningEvent: CalendarEventInfo?
    package var event: CalendarEventInfo?
    package var calendar: Calendar = .current
    package var askEveryMinutes = Limits.trackerAskEveryDefault
    package var shortcut: KeyShortcut?
    package var places: [String] = []
    package var actions = TrackerPromptActions()

    package init(kind: PromptKind, shownAt: Date, now: Date, draft: ActivityDraft) {
        self.kind = kind
        self.shownAt = shownAt
        self.now = now
        self.draft = draft
    }

    package var showsSwitchRow: Bool { !switchTimes.isEmpty }
    package var isLate: Bool { waitedMinutes != nil }
}
