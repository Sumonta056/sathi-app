import SathiCore
import SwiftUI

struct SoundLink: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        Button { e.openSettings(.sound) } label: {
            HStack(spacing: UIMetrics.chipSpacing) {
                Image(systemName: "speaker.wave.2")
                Text(verbatim: Copywriter.settingsSoundLink)
                    .font(Typography.rowLabel)
                Spacer(minLength: 0)
            }
            .foregroundStyle(Night.calm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
