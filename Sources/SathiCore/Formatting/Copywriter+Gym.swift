import Foundation

extension Copywriter {
    package static func gymInviteHint(_ w: GymWorkout) -> String {
        "\(w.name) · \(w.minutes) min"
    }

    package static func gymTimerLine() -> String {
        "Go at your own pace. Every move counts."
    }
}
