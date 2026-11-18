import Foundation

package struct CalendarPlacedBlock: Equatable, Sendable {
    package var block: CalendarBlock
    package var span: DateInterval
    package var displaySpan: DateInterval
    package var lane: Int
    package var lanes: Int
    package var depth: Int
    package var isBackdrop: Bool
    package var isRaised: Bool
    package var hostID: String?
    package var children: [CalendarPlacedBlock]
    package var hidden: [CalendarPlacedBlock]

    package init(
        block: CalendarBlock,
        span: DateInterval? = nil,
        lane: Int,
        lanes: Int,
        depth: Int = 0,
        isBackdrop: Bool = false,
        hostID: String? = nil
    ) {
        self.block = block
        self.span = span ?? block.interval
        displaySpan = self.span
        self.lane = lane
        self.lanes = lanes
        self.depth = depth
        self.isBackdrop = isBackdrop
        isRaised = depth > 0
        self.hostID = hostID
        children = []
        hidden = []
    }

    package var hiddenCount: Int { hidden.count }
}
