import SathiCore
import SwiftUI

struct TrackerPlaceChip: View {
    let name: String
    let remove: (() -> Void)?

    var body: some View {
        if let remove {
            Button(action: remove) { label(removable: true) }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: Copywriter.trackerRemovePlace(name)))
        } else {
            label(removable: false)
        }
    }

    private func label(removable: Bool) -> some View {
        let shape = Capsule()
        return HStack(spacing: UIMetrics.trackerChipSpacing) {
            Text(verbatim: name)
                .font(Typography.tracker(UIMetrics.trackerPlaceFont, .semibold))
                .foregroundStyle(removable ? Night.chipText : Night.muted)
            if removable {
                Image(systemName: "xmark")
                    .font(.system(size: UIMetrics.trackerRemoveIcon, weight: .bold))
                    .foregroundStyle(Night.muted)
            }
        }
        .padding(.horizontal, UIMetrics.trackerPillPadding)
        .frame(height: UIMetrics.trackerPillHeight)
        .overlay(shape.strokeBorder(Night.fieldBorder, lineWidth: UIMetrics.trackerChipBorder))
        .contentShape(shape)
        .accessibilityIdentifier(removable ? "settings.tracker.place.remove." + name : "settings.tracker.place.builtin." + name)
    }
}
