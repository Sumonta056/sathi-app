import Foundation

package enum RangeChange: Equatable {
    case up(Double)
    case down(Double)
    case same
    case none

    package init(current: Double, previous: Double, hasData: Bool) {
        if !hasData {
            self = .none
        } else if current > previous {
            self = .up(current - previous)
        } else if current < previous {
            self = .down(previous - current)
        } else {
            self = .same
        }
    }
}
