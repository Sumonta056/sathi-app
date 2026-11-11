import SathiCore
import SwiftUI

struct ActivityTile: View {
    let label: String
    let value: String
    let note: String
    var accent: Color = Night.tracker
    var change: RangeChange = .none
    var changeText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.textSpacing) {
            HStack(spacing: UIMetrics.dotSpacing) {
                Circle().fill(accent).frame(width: UIMetrics.dotSize, height: UIMetrics.dotSize)
                Text(verbatim: label)
                    .font(Typography.sectionLabel)
                    .tracking(UIMetrics.labelTracking)
                    .foregroundStyle(Night.label)
            }
            Text(verbatim: value)
                .font(.system(size: UIMetrics.trackerTileValueFont, weight: .black, design: .rounded))
                .foregroundStyle(Night.text)
                .lineLimit(1)
                .minimumScaleFactor(UIMetrics.trackerTileMinScale)
            Text(verbatim: note)
                .font(Typography.hint)
                .foregroundStyle(Night.muted)
                .lineLimit(1)
            RangeChangeText(change: change, text: changeText)
        }
        .padding(UIMetrics.trackerTilePadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(shape.fill(Night.card))
        .overlay(shape.strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.trackerTileRadius, style: .continuous)
    }
}
