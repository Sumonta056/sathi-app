import Foundation

package struct CalendarPlacedBlock: Equatable {
    package var block: CalendarBlock
    package var span: DateInterval
    package var lane: Int
    package var lanes: Int
    package var depth: Int
    package var isBackdrop: Bool

    package init(block: CalendarBlock, span: DateInterval? = nil, lane: Int, lanes: Int, depth: Int = 0, isBackdrop: Bool = false) {
        self.block = block
        self.span = span ?? block.interval
        self.lane = lane
        self.lanes = lanes
        self.depth = depth
        self.isBackdrop = isBackdrop
    }
}
