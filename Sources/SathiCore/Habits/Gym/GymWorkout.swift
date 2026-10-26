import Foundation

package struct GymWorkout: Codable, Equatable, Sendable {
    package var name: String
    package var minutes: Int

    package init(name: String, minutes: Int) {
        self.name = name
        self.minutes = minutes
    }

    package static let defaults: [GymWorkout] = [
        GymWorkout(name: "Neck and shoulder stretch", minutes: 5),
        GymWorkout(name: "Short walk", minutes: 5),
        GymWorkout(name: "10 squats", minutes: 3),
        GymWorkout(name: "Wall push-ups", minutes: 3)
    ]
}
