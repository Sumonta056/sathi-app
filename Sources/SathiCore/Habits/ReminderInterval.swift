import Foundation

package enum ReminderInterval {
    package static func nearest(_ minutes: Int) -> Int {
        Limits.intervalChips.min { abs($0 - minutes) < abs($1 - minutes) } ?? minutes
    }
}
