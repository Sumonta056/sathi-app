import Foundation

extension Engine {
    package var runningActivity: RunningActivity? { data.live.tracker.running }
    package var trackerPrompt: PromptState? { data.live.tracker.prompt }
    package var trackerQuietUntil: Date? { data.live.tracker.running?.quietUntil }
    package var recentActivities: [RecentActivity] { [] }

    package func trackerPromptState(_ kind: PromptKind) -> TrackerPromptState? { nil }
    package func trackerEndOfDayState() -> TrackerEndOfDayState? { nil }

    package func startActivity(_ draft: ActivityDraft, switchAt: Date? = nil) {}
    package func skipTrackerPrompt(switchAt: Date? = nil) {}
    package func stillOnIt(minutes: Int? = nil) {}
    package func stillOnItLate() {}
    package func doneActivity() {}
    package func continueActivity(switchAt: Date? = nil) {}
    package func backToLastActivity() {}
    package func iWasHere() {}
    package func setAwayPlace(_ place: AwayPlace) {}
    package func closeTrackerPrompt() {}
    package func openTrackerPanel() {}
    package func trackerShortcutPressed() {}
    package func endQuietTime() {}
    package func presenceChanged(_ event: PresenceEvent) {}
    package func closeTrackerEndOfDay() {}
    package func openActivityReport(_ day: DayKey) {}
}
