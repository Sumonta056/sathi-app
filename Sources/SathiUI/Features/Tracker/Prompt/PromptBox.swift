import SathiCore
import SwiftUI

struct PromptBoxLook {
    var height = UIMetrics.promptBoxHeight
    var font = UIMetrics.promptRowFont
    var padding = UIMetrics.promptBoxPadding
    var offFill = Night.promptBox
    var offLine = Night.promptBoxLine
    var offText = Night.chipText
    var onFill: Color?

    static let choice = PromptBoxLook()

    static let place = PromptBoxLook(
        height: UIMetrics.promptWhereHeight, font: UIMetrics.promptWhereFont, padding: UIMetrics.promptWherePadding,
        offFill: .clear, offLine: Night.promptBackLine, offText: Night.sproutLight, onFill: Night.promptBack
    )

    static func solid(_ color: Color) -> PromptBoxLook {
        PromptBoxLook(onFill: color)
    }
}

struct PromptBox: View {
    let label: String
    let on: Bool
    var id = ""
    var dot: Color?
    var look = PromptBoxLook.choice
    let action: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.promptBoxRadius, style: .continuous)
        Button(action: action) {
            HStack(spacing: UIMetrics.promptBoxGap) {
                if let dot { Circle().fill(dot).frame(width: UIMetrics.promptBoxDot, height: UIMetrics.promptBoxDot) }
                Text(verbatim: label)
                    .font(Typography.tracker(look.font, on ? .bold : .medium))
                    .foregroundStyle(textColor)
                    .lineLimit(1)
                    .fixedSize()
            }
            .padding(.horizontal, look.padding)
            .frame(height: look.height)
            .background(shape.fill(fill))
            .overlay(shape.strokeBorder(line, lineWidth: UIMetrics.promptBorder))
            .contentShape(shape)
            .accessibilityIdentifier(id)
        }
        .buttonStyle(TrackerPressStyle())
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private var fill: Color {
        guard on else { return look.offFill }
        return look.onFill ?? Night.trackerSelectedFill
    }

    private var line: Color {
        guard on else { return look.offLine }
        return look.onFill == nil ? Night.tracker : .clear
    }

    private var textColor: Color {
        guard on else { return look.offText }
        return look.onFill == nil ? Night.trackerSelectedText : Night.onAccent
    }
}
