import SathiCore
import SwiftUI

struct GymWorkoutsCard: View {
    private static let rows = Array(0 ..< Limits.gymWorkoutCount)
    private static let orderNote = "Shokti uses them in order: "
        + rows.map { "\($0 + 1)" }.joined(separator: " → ") + "."

    @EnvironmentObject var e: Engine

    var body: some View {
        let engine = e
        VStack(alignment: .leading, spacing: UIMetrics.sectionSpacing) {
            SettingsCard {
                ForEach(Self.rows, id: \.self) { GymWorkoutRow(index: $0) }
            }
            Text(verbatim: Self.orderNote)
                .font(Typography.hint)
                .foregroundStyle(Night.muted)
        }
        .onDisappear { engine.commitGymWorkoutNames() }
    }
}
