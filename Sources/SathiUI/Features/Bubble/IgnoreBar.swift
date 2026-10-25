import SathiCore
import SwiftUI

struct IgnoreBar: View {
    @EnvironmentObject var e: Engine
    let id: HabitID
    let accent: Color
    let track: Color
    var label: Color = Night.muted

    private var minutes: Int { max(1, e.data.prefs.general.ignoreMinutes) }

    static func fraction(deadline: Date, now: Date, total: TimeInterval) -> Double {
        guard total > 0 else { return 0 }
        return min(1, max(0, deadline.timeIntervalSince(now) / total))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.ignoreBarSpacing) {
            TimelineView(.periodic(from: .now, by: UIMetrics.ignoreBarRefresh)) { tl in
                let total = Double(minutes) * Timing.minute
                ZStack {
                    Capsule().fill(track)
                    Capsule().fill(accent)
                        .scaleEffect(x: Self.fraction(deadline: e.ignoreDeadline(id), now: tl.date, total: total), y: 1, anchor: .leading)
                }
            }
            .frame(height: UIMetrics.ignoreBarHeight)
            Text("No answer in \(minutes) \(minutes == 1 ? "minute" : "minutes") counts as a snooze.")
                .font(Typography.hint)
                .foregroundStyle(label)
        }
    }
}
