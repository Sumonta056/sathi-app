import Foundation

package struct CalendarGridRow: Equatable, Sendable {
    package var startMinute: Int
    package var endMinute: Int
    package var top: Double
    package var height: Double
    package var isFold: Bool

    package init(startMinute: Int, endMinute: Int, top: Double, height: Double, isFold: Bool) {
        self.startMinute = startMinute
        self.endMinute = endMinute
        self.top = top
        self.height = height
        self.isFold = isFold
    }

    package var bottom: Double { top + height }

    package func holds(_ minute: Int) -> Bool {
        startMinute <= minute && minute < endMinute
    }
}
