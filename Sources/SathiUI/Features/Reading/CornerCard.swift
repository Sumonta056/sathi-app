import SathiCore
import SwiftUI

struct CornerCard: ViewModifier {
    var width = UIMetrics.cornerWidth
    var alert = false
    var habit: HabitID = .reading
    var border: Color?
    var alertColor: Color?

    func body(content: Content) -> some View {
        content
            .padding(UIMetrics.cornerPadding)
            .frame(width: width)
            .background(shape.fill(Night.card))
            .overlay(shape.strokeBorder(
                alert ? alertColor ?? Night.accent(habit) : border ?? Night.heroBorder(habit),
                lineWidth: alert ? UIMetrics.bubbleAlertBorder : UIMetrics.bubbleBorder
            ))
            .padding(UIMetrics.bubbleShadowPadding)
            .environment(\.colorScheme, .dark)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.cornerRadius, style: .continuous)
    }
}

struct CornerCloseButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: UIMetrics.closeIconSize, weight: .bold))
                .foregroundStyle(Night.muted)
                .frame(width: UIMetrics.closeButtonSize, height: UIMetrics.closeButtonSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
