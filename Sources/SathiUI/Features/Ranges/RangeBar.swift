import SathiCore
import SwiftUI

struct RangeBar: View {
    @Binding var range: StatsRange
    let now: Date
    let calendar: Calendar

    var body: some View {
        HStack(spacing: UIMetrics.rangeBarGap) {
            PillSegment(options: ReportRange.allCases, selected: kind, title: Copywriter.rangeSegment)
            HStack(spacing: UIMetrics.rangeBarGap) {
                arrow("chevron.left", label: Copywriter.rangePrevious, enabled: true) { range = range.previous }
                Text(verbatim: Copywriter.rangeTitle(range, now: now, calendar: calendar))
                    .font(Typography.rowLabel)
                    .foregroundStyle(Night.text)
                    .frame(minWidth: UIMetrics.rangeTitleWidth)
                arrow("chevron.right", label: Copywriter.rangeNext, enabled: range.canGoForward(now: now)) { range = range.next }
            }
        }
    }

    private var kind: Binding<ReportRange> {
        Binding(get: { range.kind }, set: { range = range.changed(to: $0, now: now) })
    }

    private func arrow(_ icon: String, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(Typography.chip)
                .foregroundStyle(Night.text)
                .frame(width: UIMetrics.rangeArrowSize, height: UIMetrics.rangeArrowSize)
                .background(shape.fill(Night.card))
                .overlay(shape.strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : UIMetrics.reportsOffOpacity)
        .accessibilityLabel(label)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.rangeArrowRadius, style: .continuous)
    }
}
