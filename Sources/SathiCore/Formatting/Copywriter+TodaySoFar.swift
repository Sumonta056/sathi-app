import Foundation

extension Copywriter {
    package static func todaySoFarChange(_ change: RangeChange) -> String {
        rangeChange(change, kind: .day) { categoryTableHours($0) }
    }
}
