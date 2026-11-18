import SwiftUI

struct TodoAddButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Face(configuration: configuration)
    }

    private struct Face: View {
        let configuration: Configuration
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(Typography.tracker(UIMetrics.todoAddButtonFont, .heavy))
                .lineLimit(1)
                .padding(UIMetrics.todoAddButtonPadding)
                .foregroundStyle(isEnabled ? Night.onAccent : Night.faint)
                .background(shape.fill(isEnabled ? Night.todo : Night.navSelected))
                .opacity(configuration.isPressed ? UIMetrics.pillPressedOpacity : 1)
                .contentShape(shape)
        }

        private var shape: RoundedRectangle {
            RoundedRectangle(cornerRadius: UIMetrics.todoChipRadius, style: .continuous)
        }
    }
}
