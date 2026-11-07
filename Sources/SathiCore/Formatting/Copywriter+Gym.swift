import Foundation

extension Copywriter {
    package static func gymInviteTitle(idea: String, name: String) -> String {
        "Try \(sentenceCase(idea)), \(displayName(name))"
    }

    package static func gymInviteLine(minutes: Int) -> String {
        "\(minutes) minutes. You can do this."
    }

    package static func gymProgressText(_ p: GymProgress) -> String {
        "\(p.doneMinutes) of \(p.goalMinutes) min today · session \(p.current) of \(p.sessions)"
    }

    package static func gymTimerLine() -> String {
        "Go at your own pace. Every move counts."
    }

    private static func sentenceCase(_ idea: String) -> String {
        guard let first = idea.first, let second = idea.dropFirst().first, second.isLowercase else { return idea }
        return first.lowercased() + idea.dropFirst()
    }
}

extension Copywriter {
    package static func gymGoalSummary(_ g: GymPrefs) -> String {
        "Daily goal: \(g.dailyGoalMinutes) min · \(g.sessionsPerDay) × \(g.sessionMinutes) min"
    }

    package static func gymPopupTimes(_ g: GymPrefs, calendar: Calendar = .current) -> String {
        "Popups at " + g.popupMinutes.map { Fmt.timeOfDay($0, calendar: calendar) }.joined(separator: ", ")
    }
}
