import Foundation

extension Copywriter {
    package static let activityPromptNowRunning = "NOW RUNNING"
    package static let activityPromptBeforeYouLeft = "BEFORE YOU LEFT"
    package static let activityPromptLastActivity = "LAST ACTIVITY"
    package static let activityPromptOrSwitch = "or switch to something new"
    package static let activityPromptWelcomeTitle = "Welcome back. Where were you?"
    package static let activityPromptKeepItOrSwitch = "Keep it, or type a new one to switch."
    package static let activityPromptContinueOrStart = "Continue it, or start something new."

    package static func activityPromptStillTitle(_ text: String) -> String { "Still on " + text + "?" }

    package static func activityPromptKeepOrSwitch(minutes: Int) -> String { "\(minutes) min so far. Keep going, or switch." }

    package static func activityPromptCardDetail(start: Date, minutes: Int, length: Int?, calendar: Calendar) -> String {
        let started = "Started " + trackerClock(start, calendar: calendar) + " · "
        guard let length else { return started + "\(minutes) min so far" }
        return started + "\(minutes) of \(length) min"
    }
}
