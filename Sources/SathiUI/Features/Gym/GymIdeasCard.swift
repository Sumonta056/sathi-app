import SathiCore
import SwiftUI

struct GymIdeasCard: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let engine = e
        let count = engine.data.prefs.gym.ideas.count
        VStack(alignment: .leading, spacing: UIMetrics.sectionSpacing) {
            SettingsCard {
                ForEach(0 ..< count, id: \.self) { GymIdeaRow(index: $0) }
            }
            HStack {
                Button { engine.addGymIdea() } label: { Text(verbatim: "+ Add idea") }
                    .buttonStyle(GhostButton(accent: Night.gym, height: UIMetrics.chipHeight, border: Night.heroBorder(.gym)))
                    .disabled(count >= Limits.gymIdeasMax)
                Spacer()
                Text(verbatim: "\(count) of \(Limits.gymIdeasMax)")
                    .font(Typography.hint)
                    .foregroundStyle(Night.muted)
            }
        }
        .onDisappear { engine.commitGymIdeas() }
    }
}
