import SathiCore
import SwiftUI

struct IgnoreBar: View {
    @EnvironmentObject var e: Engine
    let accent: Color

    var body: some View {
        TimelineView(.periodic(from: .now, by: UIMetrics.ignoreBarRefresh)) { tl in
            let total = Double(max(1, e.data.prefs.general.ignoreMinutes)) * Timing.minute
            let left = max(0, e.ignoreDeadline.timeIntervalSince(tl.date))
            VStack(alignment: .leading, spacing: 6) {
                ProgressBar(value: left / total, tint: accent, height: 4, track: Color.black.opacity(0.08))
                Text("Ignore me for \(Fmt.clock(left)) more and it counts as a snooze")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Palette.muted)
                    .monospacedDigit()
            }
        }
    }
}
