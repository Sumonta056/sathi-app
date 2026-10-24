import Foundation

package struct DrinkEntry: Codable, Equatable, Sendable {
    package var date: Date
    package var glasses: Double

    package init(date: Date, glasses: Double) {
        self.date = date
        self.glasses = glasses
    }
}

package struct ReadEntry: Codable, Equatable, Sendable {
    package var date: Date
    package var minutes: Int

    package init(date: Date, minutes: Int) {
        self.date = date
        self.minutes = minutes
    }
}
