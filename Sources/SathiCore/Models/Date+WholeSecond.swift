import Foundation

extension Date {
    package var wholeSecond: Date {
        Date(timeIntervalSinceReferenceDate: floor(timeIntervalSinceReferenceDate))
    }
}
