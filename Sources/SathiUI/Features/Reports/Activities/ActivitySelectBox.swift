import SwiftUI

struct ActivitySelectBox: View {
    let on: Bool
    let label: String
    var action: () -> Void = {}

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.mergeBoxRadius, style: .continuous)
        Button(action: action) {
            ZStack {
                shape.fill(on ? Night.tracker : Night.card)
                shape.strokeBorder(on ? Night.tracker : Night.fieldBorder, lineWidth: UIMetrics.mergeBoxBorder)
                if on {
                    Image(systemName: "checkmark")
                        .font(.system(size: UIMetrics.mergeBoxIcon, weight: .heavy))
                        .foregroundStyle(Night.onAccent)
                }
            }
            .frame(width: UIMetrics.mergeBox, height: UIMetrics.mergeBox)
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: label))
    }
}
