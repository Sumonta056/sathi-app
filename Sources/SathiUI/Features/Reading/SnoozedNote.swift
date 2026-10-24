import SathiCore
import SwiftUI

struct SnoozedNote: View {
    @EnvironmentObject var e: Engine
    let id: HabitID
    let until: Date

    var body: some View {
        Text(e.comesBackText(id, until: until))
            .font(Typography.hint)
            .foregroundStyle(Night.chipText)
            .padding(UIMetrics.notePadding)
            .background(Capsule().fill(Night.card))
            .overlay(Capsule().strokeBorder(Night.border, lineWidth: UIMetrics.bubbleBorder))
            .modifier(CornerShadow())
            .padding(UIMetrics.bubbleShadowPadding)
            .environment(\.colorScheme, .dark)
    }
}
