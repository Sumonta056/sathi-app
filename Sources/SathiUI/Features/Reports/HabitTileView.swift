import SathiCore
import SwiftUI

struct HabitTileView: View {
    let tile: ReportTile
    @Binding var selected: HabitID

    var body: some View {
        let on = selected == tile.habit && !tile.isOff
        let accent = Night.accent(tile.habit)
        Button { selected = tile.habit } label: {
            VStack(alignment: .leading, spacing: UIMetrics.sectionSpacing) {
                HStack(spacing: UIMetrics.dotSpacing) {
                    Circle()
                        .fill(accent)
                        .frame(width: UIMetrics.dotSize, height: UIMetrics.dotSize)
                    Text(verbatim: tile.label)
                        .font(Typography.sectionLabel)
                        .tracking(UIMetrics.labelTracking)
                        .foregroundStyle(Night.label)
                }
                HStack(alignment: .firstTextBaseline, spacing: UIMetrics.textSpacing) {
                    Text(verbatim: tile.value)
                        .font(Typography.bigNumber)
                        .foregroundStyle(Night.text)
                    Text(verbatim: tile.unit)
                        .font(Typography.hint)
                        .foregroundStyle(Night.muted)
                }
                ProgressBar(
                    value: Double(tile.percent) / Double(Limits.fullPercent),
                    tint: accent,
                    height: UIMetrics.tileMeterHeight,
                    track: Night.divider
                )
                Text(verbatim: tile.note)
                    .font(Typography.hint)
                    .foregroundStyle(Night.muted)
            }
            .padding(UIMetrics.tilePadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(shape.fill(Night.card))
            .overlay(shape.strokeBorder(on ? accent : Night.border, lineWidth: on ? UIMetrics.tileSelectedBorder : UIMetrics.cardBorder))
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .disabled(tile.isOff)
        .opacity(tile.isOff ? UIMetrics.reportsOffOpacity : 1)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.cardRadius, style: .continuous)
    }
}
