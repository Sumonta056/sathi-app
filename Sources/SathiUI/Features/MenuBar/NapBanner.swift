import SathiCore
import SwiftUI

struct NapBanner: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        HStack(spacing: UIMetrics.menuSpacing) {
            Image(systemName: "pause.circle.fill")
                .accessibilityHidden(true)
            Text("Buddies are napping until \(e.pauseEndText)")
                .font(Typography.hint)
            Spacer()
            Button("Wake up") { e.resume() }
                .buttonStyle(GhostButton(accent: Night.reading, height: UIMetrics.actionHeight))
        }
        .foregroundStyle(Night.reading)
        .padding(UIMetrics.bannerPadding)
        .background(shape.fill(Night.heroFill(.reading)))
        .overlay(shape.strokeBorder(Night.heroBorder(.reading), lineWidth: UIMetrics.cardBorder))
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.cardRadius, style: .continuous)
    }
}
