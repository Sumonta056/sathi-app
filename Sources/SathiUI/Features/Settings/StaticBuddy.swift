import SathiCore
import SwiftUI

struct StaticBuddy: View {
    let habit: HabitID
    var size: CGFloat = UIMetrics.heroBuddySize

    var body: some View {
        BuddyCanvas(kind: habit.kind, mood: .happy, level: 1, t: 0)
            .frame(width: size * UIMetrics.buddyAspect, height: size)
            .accessibilityHidden(true)
    }
}
