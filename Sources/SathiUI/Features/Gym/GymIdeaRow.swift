import SathiCore
import SwiftUI

struct GymIdeaRow: View {
    @EnvironmentObject var e: Engine
    let index: Int

    var body: some View {
        let engine = e
        let name = engine.gymIdeaName(at: index)
        HStack(spacing: UIMetrics.chipSpacing) {
            LazyTextField(
                placeholder: "Idea \(index + 1)",
                text: name,
                startsEditing: name.wrappedValue.isEmpty
            )
            Button { engine.removeGymIdea(at: index) } label: {
                Image(systemName: "xmark")
                    .font(.system(size: UIMetrics.gymIconSize, weight: .bold))
                    .foregroundStyle(Night.muted)
                    .frame(width: UIMetrics.chipHeight, height: UIMetrics.chipHeight)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(engine.data.prefs.gym.ideas.count <= 1)
            .accessibilityLabel(Text(verbatim: "Remove idea \(index + 1)"))
        }
        .padding(UIMetrics.rowPadding)
        .overlay(alignment: .top) {
            if index > 0 {
                Rectangle().fill(Night.divider).frame(height: UIMetrics.dividerHeight)
            }
        }
    }
}
