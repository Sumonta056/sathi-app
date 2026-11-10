import SathiCore
import SwiftUI

struct TrackerPlacesRow: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let engine = e
        VStack(alignment: .leading, spacing: UIMetrics.trackerPlaceBoxSpacing) {
            SettingRow(label: Copywriter.trackerPlacesLabel, hint: Copywriter.trackerPlacesHint, showsDivider: false) { EmptyView() }
            if engine.awayPlaces.isEmpty {
                Text(verbatim: Copywriter.trackerPlacesEmpty)
                    .font(Typography.hint)
                    .foregroundStyle(Night.faint)
            } else {
                TrackerFlowLayout(spacing: UIMetrics.trackerChipSpacing) {
                    ForEach(engine.awayPlaces, id: \.self) { name in
                        chip(name) { engine.removeAwayPlace(name) }
                    }
                }
            }
        }
    }

    private func chip(_ name: String, remove: @escaping () -> Void) -> some View {
        let shape = Capsule()
        return Button(action: remove) {
            HStack(spacing: UIMetrics.trackerChipSpacing) {
                Text(verbatim: name)
                    .font(Typography.tracker(UIMetrics.trackerPlaceFont, .semibold))
                    .foregroundStyle(Night.chipText)
                Image(systemName: "xmark")
                    .font(.system(size: UIMetrics.trackerRemoveIcon, weight: .bold))
                    .foregroundStyle(Night.muted)
            }
            .padding(.horizontal, UIMetrics.trackerPillPadding)
            .frame(height: UIMetrics.trackerPillHeight)
            .overlay(shape.strokeBorder(Night.fieldBorder, lineWidth: UIMetrics.trackerChipBorder))
            .contentShape(shape)
            .accessibilityIdentifier("settings.tracker.place.remove." + name)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: Copywriter.trackerRemovePlace(name)))
    }
}
