import SathiCore
import SwiftUI

struct TrackerHeader: View {
    let icon: String
    let eyebrow: String
    let title: String
    var detail: String?
    var dot: UInt32?
    var compact = true

    var body: some View {
        let size = TrackerSize.of(compact: compact)
        HStack(alignment: .center, spacing: size.headerSpacing) {
            tile(size)
            VStack(alignment: .leading, spacing: UIMetrics.trackerLineGap) {
                Text(verbatim: eyebrow)
                    .font(Typography.tracker(size.eyebrow, .heavy))
                    .tracking(size.eyebrow * UIMetrics.trackerEyebrowEm)
                    .foregroundStyle(Night.tracker)
                    .lineLimit(1)
                HStack(spacing: UIMetrics.trackerTitleDotGap) {
                    if let dot { Circle().fill(Color(hex: dot)).frame(width: UIMetrics.trackerDot, height: UIMetrics.trackerDot) }
                    Text(verbatim: title)
                        .font(Typography.tracker(size.title, .bold))
                        .foregroundStyle(Night.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let detail {
                    Text(verbatim: detail)
                        .font(Typography.tracker(UIMetrics.trackerDetailFont, .medium))
                        .foregroundStyle(Night.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func tile(_ size: TrackerSize) -> some View {
        Image(systemName: icon)
            .font(.system(size: size.icon, weight: .semibold))
            .foregroundStyle(Night.tracker)
            .frame(width: size.tile, height: size.tile)
            .background(RoundedRectangle(cornerRadius: size.tileRadius, style: .continuous).fill(Night.trackerTile))
            .accessibilityHidden(true)
    }
}

struct TrackerHint: View {
    let text: String

    var body: some View {
        Text(verbatim: text)
            .font(Typography.tracker(UIMetrics.trackerHintFont, .medium))
            .foregroundStyle(Night.faint)
            .fixedSize(horizontal: false, vertical: true)
    }
}
