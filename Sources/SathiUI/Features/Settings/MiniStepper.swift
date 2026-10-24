import SwiftUI

struct MiniStepper<Value: Comparable & AdditiveArithmetic>: View {
    @Binding var value: Value
    let range: ClosedRange<Value>
    let step: Value
    let format: (Value) -> String

    var body: some View {
        HStack(spacing: UIMetrics.chipSpacing) {
            stepButton("−", label: "Less", to: value - step)
            Text(verbatim: format(value))
                .font(Typography.chip)
                .foregroundStyle(Night.text)
                .frame(minWidth: UIMetrics.stepperValueWidth)
            stepButton("+", label: "More", to: value + step)
        }
    }

    private func stepButton(_ symbol: String, label: String, to target: Value) -> some View {
        let next = min(max(target, range.lowerBound), range.upperBound)
        return RoundStepButton(symbol: symbol, label: label, enabled: next != value) { value = next }
    }
}

struct RoundStepButton: View {
    let symbol: String
    let label: String
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(verbatim: symbol)
                .font(Typography.stepperSymbol)
                .foregroundStyle(Night.text)
                .frame(width: UIMetrics.stepperButtonSize, height: UIMetrics.stepperButtonSize)
                .background(Circle().fill(Night.bg))
                .overlay(Circle().strokeBorder(Night.fieldBorder, lineWidth: UIMetrics.chipBorder))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(Text(verbatim: label))
    }
}
