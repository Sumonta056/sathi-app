import Foundation

extension Copywriter {
    package static let categoryTableTinyPercent = "<1%"
    package static let noValue = "\u{2014}"
    package static let categoryTableNoChange = "0m"

    package static func categoryCount(_ n: Int) -> String {
        n == 1 ? "1 category" : "\(n) categories"
    }

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
        case .up, .down:
            let text = rangeDelta(change) { categoryTableHours($0) }
            return text.dropFirst() == Substring(categoryTableNoChange) ? categoryTableNoChange : text
        }
    }

    package static func categoryTableHours(_ seconds: TimeInterval) -> String {
        let minutes = Int(max(0, seconds) / Timing.minute)
        return minutes == 0 ? categoryTableNoChange : Fmt.short(TimeInterval(minutes) * Timing.minute)
    }
}
