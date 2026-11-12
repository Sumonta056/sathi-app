import Foundation

package struct ReportChart: Equatable, Sendable {
    package var title: String
    package var bars: [ReportBar]
    package var goal: Double?
}

package struct ReportBar: Equatable, Sendable, Identifiable {
    package var id: Int
    package var label: String
    package var value: Double
    package var metGoal: Bool
}

package struct ReportFact: Equatable, Sendable, Identifiable {
    package var label: String
    package var id: String { label }
    package var value: String
}
