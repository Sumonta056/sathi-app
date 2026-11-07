import SathiCore
import SwiftUI

struct GymProgressBar: View {
    let progress: GymProgress

    static func isFilled(_ index: Int, _ p: GymProgress) -> Bool { index < p.filled }

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.gymBarSpacing) {
            HStack(spacing: UIMetrics.gymBarGap) {
                ForEach(0 ..< progress.sessions, id: \.self) { i in
                    Capsule()
                        .fill(Self.isFilled(i, progress) ? Night.gym : Night.switchOff)
                        .frame(height: UIMetrics.gymProgressHeight)
                }
            }
            .accessibilityHidden(true)
            Text(verbatim: Copywriter.gymProgressText(progress))
                .font(Typography.hint)
                .foregroundStyle(Night.muted)
        }
    }
}
