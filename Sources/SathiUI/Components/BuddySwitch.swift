import SwiftUI

struct BuddySwitch: View {
    @Binding var isOn: Bool
    let accent: Color
    let label: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var travel: CGFloat {
        (UIMetrics.switchSize.width - UIMetrics.switchSize.height) / 2
    }

    private var motion: Animation? {
        reduceMotion ? nil : .spring(response: UIMetrics.switchSpringResponse, dampingFraction: UIMetrics.switchSpringDamping)
    }

    var body: some View {
        Button { isOn.toggle() } label: {
            ZStack {
                Capsule().fill(isOn ? accent : Night.switchOff)
                Circle()
                    .fill(.white)
                    .frame(width: UIMetrics.switchKnob, height: UIMetrics.switchKnob)
                    .offset(x: isOn ? travel : -travel)
            }
            .frame(width: UIMetrics.switchSize.width, height: UIMetrics.switchSize.height)
            .animation(motion, value: isOn)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: label))
        .accessibilityValue(Text(verbatim: isOn ? "On" : "Off"))
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
