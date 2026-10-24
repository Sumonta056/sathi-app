import SathiCore
import SwiftUI

struct BobbingBuddy: View {
    let habit: HabitID
    var size: CGFloat = UIMetrics.bubbleBuddySize

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false

    static func offset(at t: TimeInterval) -> CGFloat {
        let cycle = 2 * UIMetrics.bobDuration
        return -UIMetrics.bobHeight * CGFloat(1 - cos(2 * .pi * t / cycle)) / 2
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: UIMetrics.animationFrameInterval, paused: !isVisible || reduceMotion)) { tl in
            StaticBuddy(habit: habit, size: size)
                .offset(y: reduceMotion ? 0 : Self.offset(at: tl.date.timeIntervalSinceReferenceDate))
        }
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
    }
}
