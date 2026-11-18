import Foundation

package struct CalendarLaidBlock: Equatable, Identifiable, Sendable {
    package var block: CalendarBlock
    package var span: DateInterval
    package var rounded: DateInterval
    package var half: CalendarHalf
    package var lane = 0
    package var lanes = 1
    package var depth = 0
    package var top = 0.0
    package var bottom = 0.0
    package var hidden: [CalendarLaidBlock] = []
    package var doneDuring: String?
    package var doneDuringCount = 0

    package init(block: CalendarBlock, span: DateInterval, half: CalendarHalf, rounded: DateInterval? = nil) {
        self.block = block
        self.span = span
        self.rounded = rounded ?? span
        self.half = half
    }

    package var id: String { block.id }
    package var isRaised: Bool { depth > 0 }
    package var isTodo: Bool {
        if case .todo = block.source { return true }
        return false
    }
}
