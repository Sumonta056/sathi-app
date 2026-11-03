import Foundation

package enum DaySummaryStatus: Equatable, Sendable {
    case off
    case dayOff
    case progress(done: Double, goal: Double)

    package var isMet: Bool {
        guard case let .progress(done, goal) = self else { return false }
        return goal > 0 && done >= goal
    }
}

package enum DaySummaryVerdict: Equatable, Sendable {
    case allMet
    case someMet(met: Int, of: Int)
    case noneMet
    case restDay
}

package struct DaySummaryRow: Equatable, Sendable {
    package var id: HabitID
    package var status: DaySummaryStatus
    package var streak: Int

    package init(id: HabitID, status: DaySummaryStatus, streak: Int) {
        self.id = id
        self.status = status
        self.streak = streak
    }
}

package struct DaySummary: Equatable, Sendable {
    package var rows: [DaySummaryRow]

    package init(rows: [DaySummaryRow]) {
        self.rows = rows
    }

    package var verdict: DaySummaryVerdict {
        let progress = rows.map(\.status).filter { if case .progress = $0 { return true } else { return false } }
        let met = progress.filter(\.isMet).count
        if progress.isEmpty { return .restDay }
        if met == progress.count { return .allMet }
        if met == 0 { return .noneMet }
        return .someMet(met: met, of: progress.count)
    }
}
