import SathiCore
import SwiftUI

struct BlockPopupHeader: View {
    var icon: String?
    let eyebrow: String
    var eyebrowColor = Night.block
    let title: String
    let detail: String
    var dot: UInt32?
    var onClose: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: UIMetrics.blockRowSpacing) {
            if let icon { BlockTile(icon: icon) }
            VStack(alignment: .leading, spacing: UIMetrics.blockPopupTextSpacing) {
                Text(verbatim: eyebrow)
                    .font(Typography.eyebrow)
                    .foregroundStyle(eyebrowColor)
                Text(verbatim: title)
                    .font(Typography.cornerTitle)
                    .foregroundStyle(Night.text)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: UIMetrics.blockMenuSpacing) {
                    if let dot { CalendarDot(hex: dot) }
                    Text(verbatim: detail)
                        .font(Typography.hint)
                        .foregroundStyle(Night.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
            if let onClose { CornerCloseButton(label: "Close", action: onClose) }
        }
    }
}

struct BlockTile: View {
    let icon: String

    var body: some View {
        let tile = RoundedRectangle(cornerRadius: UIMetrics.blockButtonRadius, style: .continuous)
        Image(systemName: icon)
            .font(.system(size: UIMetrics.blockTileIcon, weight: .semibold))
            .foregroundStyle(Night.block)
            .frame(width: UIMetrics.blockTileSize, height: UIMetrics.blockTileSize)
            .background(tile.fill(Night.blockFill))
            .overlay(tile.strokeBorder(Night.blockBorder, lineWidth: UIMetrics.cardBorder))
    }
}

struct BlockPopupActions: View {
    let primary: String
    let primaryID: String
    let onPrimary: () -> Void
    let secondary: String
    let secondaryID: String
    let onSecondary: () -> Void

    var body: some View {
        HStack(spacing: UIMetrics.blockPopupButtonSpacing) {
            Button(action: onPrimary) {
                Text(verbatim: primary)
                    .font(Typography.rowLabel)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier(primaryID)
            }
            .buttonStyle(AccentButton(accent: Night.block, height: UIMetrics.blockStartHeight, radius: UIMetrics.blockButtonRadius))
            Button(action: onSecondary) {
                Text(verbatim: secondary).accessibilityIdentifier(secondaryID)
            }
            .buttonStyle(BlockSecondaryButton())
        }
    }
}

struct BlockSecondaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.blockButtonRadius, style: .continuous)
        return configuration.label
            .font(Typography.rowLabel)
            .foregroundStyle(Night.text)
            .padding(.horizontal, UIMetrics.blockSecondaryPadding)
            .frame(height: UIMetrics.blockStartHeight)
            .background(shape.fill(Night.bg))
            .overlay(shape.strokeBorder(Night.fieldBorder, lineWidth: UIMetrics.cardBorder))
            .opacity(configuration.isPressed ? UIMetrics.pressedOpacity : 1)
            .contentShape(shape)
    }
}
