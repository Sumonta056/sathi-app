import SathiCore
import SwiftUI

struct SkipTodayButton: View {
    @EnvironmentObject var e: Engine
    let id: HabitID
    let height: CGFloat

    @State private var confirming: Bool

    init(id: HabitID, confirming: Bool = false, height: CGFloat = UIMetrics.cornerButtonHeight) {
        self.id = id
        self.height = height
        _confirming = State(initialValue: confirming)
    }

    static func warning(streak: Int) -> String {
        streak == 0 ? "Skipping counts today as missed." : "Skipping resets your \(streak)-day streak to zero."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.chipSpacing) {
            Text(Self.warning(streak: e.streak(id)))
                .font(Typography.hint)
                .foregroundStyle(Night.muted)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: UIMetrics.chipSpacing) {
                if confirming {
                    Button { confirming = false } label: { Text("Keep my streak").frame(maxWidth: .infinity) }
                        .buttonStyle(GhostButton(accent: Night.chipText, height: height))
                    Button { e.emergencySkip(id) } label: { Text("Skip anyway").frame(maxWidth: .infinity) }
                        .buttonStyle(PillButton(kind: .danger, height: height))
                } else {
                    Button { confirming = true } label: { Text("Skip today").frame(maxWidth: .infinity) }
                        .buttonStyle(GhostButton(accent: Night.chipText, height: height))
                }
            }
        }
    }
}
