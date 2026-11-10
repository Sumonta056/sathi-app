import SathiCore
import SwiftUI

struct TrackerPrimaryButton: View {
    let label: String
    let id: String
    var height = TrackerSize.corner.buttonHeight
    var radius = TrackerSize.corner.buttonRadius
    var font = TrackerSize.corner.button
    var dot = false
    var key: String?
    let action: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        Button(action: action) {
            HStack(spacing: UIMetrics.trackerOptionRowSpacing) {
                if dot { Circle().fill(Night.trackerOnAccent).frame(width: UIMetrics.trackerBackDot, height: UIMetrics.trackerBackDot) }
                Text(verbatim: label)
                    .font(Typography.tracker(font, .heavy))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: dot ? .leading : .center)
                if let key { Text(verbatim: key).font(Typography.tracker(UIMetrics.trackerDetailFont, .bold)) }
            }
            .foregroundStyle(Night.trackerOnAccent)
            .padding(.horizontal, UIMetrics.trackerFieldPadding)
            .frame(height: height)
            .background(shape.fill(Night.tracker))
            .contentShape(shape)
            .accessibilityIdentifier(id)
        }
        .buttonStyle(TrackerPressStyle())
    }
}

struct TrackerSecondaryButton: View {
    let label: String
    let id: String
    var height = TrackerSize.corner.buttonHeight
    var width: CGFloat?
    var radius = TrackerSize.corner.buttonRadius
    var font = TrackerSize.corner.button
    var weight = Font.Weight.semibold
    var color = Night.chipText
    let action: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        Button(action: action) {
            Text(verbatim: label)
                .font(Typography.tracker(font, weight))
                .foregroundStyle(color)
                .lineLimit(1)
                .frame(maxWidth: width == nil ? .infinity : width)
                .frame(height: height)
                .overlay(shape.strokeBorder(Night.fieldBorder, lineWidth: UIMetrics.cardBorder))
                .contentShape(shape)
                .accessibilityIdentifier(id)
        }
        .buttonStyle(TrackerPressStyle())
    }
}

struct TrackerPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? UIMetrics.trackerPressedOpacity : 1)
    }
}
