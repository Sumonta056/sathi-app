import SathiCore
import SwiftUI

struct BuddyView: View {
    var kind: BuddyKind
    var mood: Mood
    var level: Double = 0.7

    @State private var isVisible = false

    var body: some View {
        TimelineView(.animation(minimumInterval: UIMetrics.animationFrameInterval, paused: !isVisible)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            BuddyCanvas(kind: kind, mood: mood, level: level, t: t)
                .scaleEffect(x: sx(t), y: sy(t), anchor: .bottom)
                .rotationEffect(.degrees(mood == .thirsty ? sin(t * 4.2) * 5 : 0), anchor: .bottom)
                .offset(y: dy(t))
        }
        .aspectRatio(UIMetrics.buddyAspect, contentMode: .fit)
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
    }

    private func dy(_ t: Double) -> CGFloat {
        switch mood {
        case .happy: return CGFloat(-1.5 + 1.5 * sin(t * 1.96))
        case .reading: return CGFloat(-1 + sin(t * 1.5))
        case .cheer: return CGFloat(-abs(sin(t * 4.2)) * 10)
        default: return 0
        }
    }

    private func sx(_ t: Double) -> CGFloat { mood == .sad ? CGFloat(1 + 0.03 * sin(t * 2.4)) : 1 }
    private func sy(_ t: Double) -> CGFloat { mood == .sad ? CGFloat(1 - 0.03 * sin(t * 2.4)) : 1 }
}
