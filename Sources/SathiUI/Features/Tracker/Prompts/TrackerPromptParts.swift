import SathiCore
import SwiftUI

struct TrackerHeader: View {
    let icon: String
    let eyebrow: String
    let title: String
    var detail: String?
    var onClose: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: UIMetrics.trackerHeaderSpacing) {
            tile
            VStack(alignment: .leading, spacing: UIMetrics.trackerNoteSpacing / 2) {
                Text(verbatim: eyebrow)
                    .font(Typography.eyebrow)
                    .tracking(UIMetrics.trackerEyebrowTracking)
                    .foregroundStyle(Night.tracker)
                Text(verbatim: title)
                    .font(Typography.cornerTitle)
                    .foregroundStyle(Night.text)
                    .fixedSize(horizontal: false, vertical: true)
                if let detail {
                    Text(verbatim: detail)
                        .font(Typography.hint)
                        .foregroundStyle(Night.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
            if let onClose { CornerCloseButton(label: Copywriter.trackerClose, action: onClose) }
        }
    }

    private var tile: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.trackerIconRadius, style: .continuous)
        return Image(systemName: icon)
            .font(.system(size: UIMetrics.trackerIcon, weight: .semibold))
            .foregroundStyle(Night.tracker)
            .frame(width: UIMetrics.trackerIconTile, height: UIMetrics.trackerIconTile)
            .background(shape.fill(Night.trackerFill))
            .overlay(shape.strokeBorder(Night.border, lineWidth: UIMetrics.trackerChipBorder))
    }
}

struct TrackerChip: View {
    let label: String
    let on: Bool
    var id = ""
    var dot: UInt32?
    let action: () -> Void

    var body: some View {
        let shape = Capsule()
        Button(action: action) {
            HStack(spacing: UIMetrics.trackerChipSpacing) {
                if let dot { Circle().fill(Color(hex: dot)).frame(width: UIMetrics.trackerDot, height: UIMetrics.trackerDot) }
                Text(verbatim: label)
                    .font(Typography.pill)
                    .foregroundStyle(on ? Night.tracker : Night.chipText)
                    .lineLimit(1)
            }
            .padding(UIMetrics.trackerChipPadding)
            .background(shape.fill(on ? Night.trackerFill : Color.clear))
            .overlay(shape.strokeBorder(
                on ? Night.tracker : Night.fieldBorder,
                lineWidth: on ? UIMetrics.trackerChipSelectedBorder : UIMetrics.trackerChipBorder
            ))
            .contentShape(shape)
            .accessibilityIdentifier(id)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

struct TrackerPrimaryButton: View {
    let label: String
    let id: String
    var height = UIMetrics.trackerButtonHeight
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(verbatim: label)
                .font(Typography.rowLabel)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier(id)
        }
        .buttonStyle(AccentButton(accent: Night.tracker, height: height, radius: UIMetrics.trackerButtonRadius))
    }
}

struct TrackerSecondaryButton: View {
    let label: String
    let id: String
    var height = UIMetrics.trackerButtonHeight
    var width: CGFloat?
    let action: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.trackerButtonRadius, style: .continuous)
        Button(action: action) {
            Text(verbatim: label)
                .font(Typography.rowLabel)
                .foregroundStyle(Night.text)
                .frame(maxWidth: width == nil ? .infinity : width)
                .frame(height: height)
                .background(shape.fill(Night.bg))
                .overlay(shape.strokeBorder(Night.fieldBorder, lineWidth: UIMetrics.cardBorder))
                .contentShape(shape)
                .accessibilityIdentifier(id)
        }
        .buttonStyle(.plain)
    }
}

extension View {
    func trackerField(height: CGFloat = UIMetrics.trackerFieldHeight) -> some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.trackerFieldRadius, style: .continuous)
        return padding(.horizontal, UIMetrics.trackerFieldPadding)
            .frame(height: height)
            .background(shape.fill(Night.bg))
            .overlay(shape.strokeBorder(Night.tracker, lineWidth: UIMetrics.trackerFieldBorder))
    }

    func trackerCornerCard() -> some View {
        modifier(CornerCard(width: UIMetrics.trackerCornerWidth, border: Night.border))
    }
}
