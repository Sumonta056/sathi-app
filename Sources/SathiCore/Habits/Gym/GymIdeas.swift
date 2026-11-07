import Foundation

package enum GymIdeas {
    package static let defaults = ["Neck and shoulder stretch", "Short walk", "10 squats", "Wall push-ups"]

    package static func cleaned(_ names: [String]) -> [String] {
        let kept = names
            .map { String($0.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Limits.gymNameMaxLength)) }
            .filter { !$0.isEmpty }
        return kept.isEmpty ? defaults : Array(kept.prefix(Limits.gymIdeasMax))
    }
}

struct LegacyGymWorkout: Decodable {
    let name: String
}
