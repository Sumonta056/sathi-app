import Foundation

package enum ReminderInterval {
    package static func nearest(_ minutes: Int, in chips: [Int] = Limits.intervalChips) -> Int {
        chips.min { abs($0 - minutes) < abs($1 - minutes) } ?? minutes
    }
}
