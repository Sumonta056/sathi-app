import Foundation

package enum TodayShare {
    package static func percent(logged: TimeInterval, hours: DateInterval?, now: Date) -> Int? {
        guard let hours else { return nil }
        let elapsed = min(now, hours.end).timeIntervalSince(hours.start)
        guard elapsed > 0 else { return nil }
        return min(Limits.fullPercent, Int((logged / elapsed * Double(Limits.fullPercent)).rounded()))
    }
}
