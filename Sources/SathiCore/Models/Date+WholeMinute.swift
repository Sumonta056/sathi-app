import Foundation

extension Date {
    package var wholeMinute: Date {
        Date(timeIntervalSinceReferenceDate: floor(timeIntervalSinceReferenceDate / Timing.minute) * Timing.minute)
    }
}
