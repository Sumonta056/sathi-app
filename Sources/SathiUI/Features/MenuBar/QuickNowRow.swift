import SathiCore
import SwiftUI

struct QuickNowRow: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        if e.data.prefs.tracker.isOn {
            HStack(spacing: UIMetrics.quickRowSpacing) {
                VStack(alignment: .leading, spacing: UIMetrics.textSpacing) {
                    if let r = e.runningActivity {
                        Text(verbatim: Copywriter.quickPanelNow(e.now.timeIntervalSince(r.start)))
                            .font(Typography.eyebrow)
                            .foregroundStyle(Night.tracker)
                        title(r.text)
                    } else {
                        title(Copywriter.trackerNotTracking)
                    }
                }
                Spacer(minLength: 0)
                Button { e.openTrackerPanel() } label: {
                    Text(verbatim: e.runningActivity == nil ? Copywriter.trackerLogActivity : Copywriter.quickPanelSwitch)
                }
                .buttonStyle(AccentButton(
                    accent: Night.tracker, height: UIMetrics.quickNowButtonHeight, text: Night.trackerOnAccent
                ))
                .accessibilityIdentifier("menu.tracker.log")
            }
            .padding(UIMetrics.quickNowPadding)
            .background(shape.fill(Night.trackerFill))
            .overlay(shape.strokeBorder(Night.tracker.opacity(UIMetrics.chipFillOpacity), lineWidth: UIMetrics.cardBorder))
        }
    }

    private func title(_ text: String) -> some View {
        Text(verbatim: text)
            .font(Typography.rowLabel)
            .foregroundStyle(Night.text)
            .lineLimit(1)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.cardRadius, style: .continuous)
    }
}
