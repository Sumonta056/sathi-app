import Foundation

extension Copywriter {
    package static let categoryTableTinyPercent = "<1%"
    package static let categoryTableNoChange = "0m"
    package static let categoryTableZeroTotal = "0m"

    package static func categoryTablePercent(_ seconds: TimeInterval, of total: TimeInterval) -> String {
        guard total > 0, seconds > 0 else { return "0%" }
        let percent = Int((seconds / total * Double(Limits.fullPercent)).rounded())
        return percent == 0 ? categoryTableTinyPercent : "\(percent)%"
    }

    package static func categoryTableChange(_ change: RangeChange) -> String {
        switch change {
        case .same: return categoryTableNoChange
        case .none: return ""
        case .up, .down: return rangeDelta(change) { Fmt.short($0) }
        }
    }
}
