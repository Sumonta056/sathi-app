import SathiCore
import SwiftUI

struct TrackerLogButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: UIMetrics.chipSpacing) {
                Image(systemName: "pencil.line")
                    .font(.system(size: UIMetrics.quickIconSize, weight: .heavy))
                    .accessibilityHidden(true)
                Text(verbatim: Copywriter.trackerLogActivity).font(Typography.rowLabel)
            }
            .foregroundStyle(Night.tracker)
            .frame(maxWidth: .infinity)
            .frame(height: UIMetrics.toolButtonHeight)
            .background(shape.fill(Night.trackerFill))
            .overlay(shape.strokeBorder(Night.tracker.opacity(UIMetrics.chipFillOpacity), lineWidth: UIMetrics.cardBorder))
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("menu.tracker.log")
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous)
    }
}

struct TrackerLogActivityButton: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        TrackerLogButton { e.openTrackerPanel() }
    }
}
