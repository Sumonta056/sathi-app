import SathiCore
import SwiftUI

struct BubbleView: View {
    let id: HabitID
    let level: Level

    var body: some View {
        switch id {
        case .water: WaterBubble(level: level)
        case .reading: LegacyBubble(id: id, level: level)
        case .meditation: MeditationInvite(level: level)
        }
    }
}
