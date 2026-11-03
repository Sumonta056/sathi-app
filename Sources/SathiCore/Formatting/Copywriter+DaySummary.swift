import Foundation

extension Copywriter {
    package static func daySummaryTitle(_ verdict: DaySummaryVerdict, name: String) -> String {
        switch verdict {
        case .allMet: return "Congratulations, \(name)!"
        case .someMet: return "Good day, \(name)."
        case .noneMet: return "Rest well, \(name)."
        case .restDay: return "Enjoy your rest, \(name)."
        }
    }

    package static func daySummaryHint(_ verdict: DaySummaryVerdict) -> String {
        switch verdict {
        case .allMet: return "Every goal met today."
        case let .someMet(met, of): return "\(met) of \(of) goals met."
        case .noneMet: return "Tomorrow is a new day."
        case .restDay: return "No goals today."
        }
    }

    package static func daySummaryValue(_ id: HabitID, done: Double, goal: Double) -> GoalText {
        let goalCount = Int(goal)
        let shown = "\(Int(min(done, goal)))"
        switch id {
        case .water: return GoalText(done: Fmt.count(done), rest: "of \(goalCount) glasses")
        case .reading, .meditation: return GoalText(done: shown, rest: "of \(goalCount) min")
        case .gym: return GoalText(done: shown, rest: "of \(goalCount) workouts")
        }
    }
}
