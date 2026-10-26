import SathiCore
import SwiftUI

struct GymWorkoutsCard: View {
    private static let rows = Array(0 ..< Limits.gymWorkoutCount)

    var body: some View {
        SettingsCard {
            ForEach(Self.rows, id: \.self) { GymWorkoutRow(index: $0) }
        }
    }
}
