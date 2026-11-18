import Foundation

package struct CalendarLaneShape: Hashable, Sendable {
    package var depth: Int
    package var lanes: Int

    package init(depth: Int, lanes: Int) {
        self.depth = depth
        self.lanes = lanes
    }
}
