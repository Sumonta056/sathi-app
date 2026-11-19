import Foundation

package struct CalendarLayoutMetrics: Equatable, Sendable {
    package var pointsPerMinute: Double
    package var minHeight: Double
    package var awayMinHeight: Double
    package var compactHeight: Double?
    package var gap: Double
    package var titleRoom: Double
    package var foldHeight: Double
    package var foldsNights: Bool

    package init(
        pointsPerMinute: Double,
        minHeight: Double,
        awayMinHeight: Double,
        compactHeight: Double?,
        gap: Double,
        titleRoom: Double,
        foldHeight: Double,
        foldsNights: Bool
    ) {
        self.pointsPerMinute = pointsPerMinute
        self.minHeight = minHeight
        self.awayMinHeight = awayMinHeight
        self.compactHeight = compactHeight
        self.gap = gap
        self.titleRoom = titleRoom
        self.foldHeight = foldHeight
        self.foldsNights = foldsNights
    }

    package func least(for block: CalendarBlock, minutes: Int) -> Double {
        if block.style == .away { return awayMinHeight }
        guard let compactHeight, Double(minutes) * pointsPerMinute < minHeight else { return minHeight }
        return compactHeight
    }
}
