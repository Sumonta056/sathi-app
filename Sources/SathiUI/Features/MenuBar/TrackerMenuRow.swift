import SathiCore
import SwiftUI

struct TrackerMenuRow: View {
    let running: RunningActivity
    let calendar: Calendar
    let accent: Color
    let onDone: () -> Void

    var body: some View {
        HStack(spacing: UIMetrics.trackerMenuRowSpacing) {
            Circle().fill(accent).frame(width: UIMetrics.trackerMenuDot, height: UIMetrics.trackerMenuDot)
            VStack(alignment: .leading, spacing: UIMetrics.textSpacing) {
                Text(verbatim: running.text)
                    .font(Typography.rowLabel)
                    .foregroundStyle(Night.text)
                    .lineLimit(1)
                Text(verbatim: Copywriter.trackerSince(running.start, calendar: calendar))
                    .font(Typography.hint)
                    .foregroundStyle(Night.muted)
            }
            Spacer(minLength: 0)
            Button(action: onDone) {
                Text(verbatim: Copywriter.trackerMenuDone)
                    .font(Typography.chip)
                    .foregroundStyle(Night.tracker)
                    .padding(.horizontal, UIMetrics.chipPadding)
                    .frame(height: UIMetrics.trackerMenuDoneHeight)
                    .overlay(Pill().strokeBorder(Night.tracker, lineWidth: UIMetrics.chipBorder))
                    .contentShape(Pill())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("menu.tracker.done")
        }
        .padding(.horizontal, UIMetrics.rowPadding.leading)
        .frame(height: UIMetrics.trackerMenuRowHeight)
        .background(shape.fill(Night.trackerFill))
        .overlay(shape.strokeBorder(Night.tracker.opacity(UIMetrics.chipFillOpacity), lineWidth: UIMetrics.cardBorder))
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous)
    }
}

struct TrackerMenuSlot: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        if let running = e.runningActivity {
            TrackerMenuRow(running: running, calendar: .current, accent: Self.accent(running, e), onDone: { e.doneActivity() })
        }
    }

    static func accent(_ running: RunningActivity, _ engine: Engine) -> Color {
        let hex = engine.activityCategories.first { $0.name == running.category }?.colorHex
        return hex.map { Color(hex: $0) } ?? Night.tracker
    }
}
