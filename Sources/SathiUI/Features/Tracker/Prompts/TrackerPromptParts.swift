import SathiCore
import SwiftUI

struct TrackerChip: View {
    let label: String
    let on: Bool
    var id = ""
    var dot: UInt32?
    var height = UIMetrics.trackerPillHeight
    var padding = UIMetrics.trackerPillPadding
    var font = UIMetrics.trackerPillFont
    let action: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: height / 2, style: .circular)
        Button(action: action) {
            HStack(spacing: UIMetrics.trackerChipSpacing) {
                if let dot { Circle().fill(Color(hex: dot)).frame(width: UIMetrics.trackerDot, height: UIMetrics.trackerDot) }
                Text(verbatim: label)
                    .font(Typography.tracker(font, on ? .bold : .semibold))
                    .foregroundStyle(on ? Night.trackerSelectedText : Night.chipText)
                    .lineLimit(1)
                    .fixedSize()
            }
            .padding(.horizontal, padding)
            .frame(height: height)
            .background(shape.fill(on ? Night.trackerSelectedFill : Color.clear))
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

struct TrackerCard: ViewModifier {
    let compact: Bool
    let width: CGFloat
    var spacing: CGFloat?

    func body(content: Content) -> some View {
        let size = TrackerSize.of(compact: compact)
        let shape = RoundedRectangle(cornerRadius: size.cardRadius, style: .continuous)
        return content
            .padding(size.cardPadding)
            .frame(width: width)
            .background(shape.fill(Night.card))
            .overlay(shape.strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
            .padding(compact ? UIMetrics.bubbleShadowPadding : 0)
            .environment(\.colorScheme, .dark)
    }
}

extension View {
    func trackerField(compact: Bool = true) -> some View {
        let size = TrackerSize.of(compact: compact)
        let shape = RoundedRectangle(cornerRadius: size.fieldRadius, style: .continuous)
        return padding(.horizontal, size.fieldPadding)
            .frame(height: size.fieldHeight)
            .background(shape.fill(Night.bg))
            .overlay(shape.strokeBorder(Night.tracker, lineWidth: UIMetrics.trackerFieldBorder))
    }

    func trackerCornerCard() -> some View {
        modifier(TrackerCard(compact: true, width: UIMetrics.trackerCornerCard))
    }

    func trackerCenterCard(width: CGFloat = UIMetrics.trackerCenterCard) -> some View {
        modifier(TrackerCard(compact: false, width: width))
    }
}
