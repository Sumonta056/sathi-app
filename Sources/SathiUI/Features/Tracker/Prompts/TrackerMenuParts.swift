import SathiCore
import SwiftUI

struct TrackerMenuRow<Trailing: View>: View {
    let label: String
    let id: String
    var dot: Color?
    var dashedDot = false
    var selected = false
    var color = Night.text
    let action: () -> Void
    @ViewBuilder let trailing: Trailing

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.trackerDropRowRadius, style: .continuous)
        Button(action: action) {
            HStack(spacing: UIMetrics.trackerDropRowPadding) {
                marker
                Text(verbatim: label)
                    .font(Typography.tracker(UIMetrics.trackerDropFont, .semibold))
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                trailing
            }
            .padding(.horizontal, UIMetrics.trackerDropRowPadding)
            .frame(height: UIMetrics.trackerDropRowHeight)
            .background(shape.fill(selected ? Night.trackerMenuRow : Color.clear))
            .contentShape(shape)
            .accessibilityIdentifier(id)
        }
        .buttonStyle(TrackerPressStyle())
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    @ViewBuilder private var marker: some View {
        if dashedDot {
            Circle()
                .strokeBorder(Night.faint, style: StrokeStyle(lineWidth: UIMetrics.trackerChipSelectedBorder, dash: UIMetrics.trackerDashedDot))
                .frame(width: UIMetrics.trackerDot, height: UIMetrics.trackerDot)
        } else {
            Circle().fill(dot ?? Night.trackerNotLogged)
                .frame(width: UIMetrics.trackerDot, height: UIMetrics.trackerDot)
        }
    }
}

struct TrackerChevron: View {
    let size: CGFloat

    var body: some View {
        Image(systemName: "chevron.down")
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(Night.muted)
            .accessibilityHidden(true)
    }
}

extension View {
    func trackerMenuList(width: CGFloat) -> some View {
        padding(UIMetrics.trackerDropPadding)
            .frame(width: width)
            .background(Night.trackerMenu)
            .environment(\.colorScheme, .dark)
    }
}
