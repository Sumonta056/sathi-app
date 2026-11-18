import Foundation

package struct CalendarLayoutMetrics: Equatable, Sendable {
    package var pointsPerMinute: Double
    package var minHeight: Double
    package var awayMinHeight: Double
    package var gap: Double
    package var titleRoom: Double
    package var foldHeight: Double
    package var foldsNights: Bool

    package init(
        pointsPerMinute: Double,
        minHeight: Double,
        awayMinHeight: Double,
        gap: Double,
        titleRoom: Double,
        foldHeight: Double,
        foldsNights: Bool
    ) {
        self.pointsPerMinute = pointsPerMinute
        self.minHeight = minHeight
        self.awayMinHeight = awayMinHeight
        self.gap = gap
        self.titleRoom = titleRoom
        self.foldHeight = foldHeight
        self.foldsNights = foldsNights
    }

    package func least(for block: CalendarBlock) -> Double {
        block.style == .away ? awayMinHeight : minHeight
    }
}
