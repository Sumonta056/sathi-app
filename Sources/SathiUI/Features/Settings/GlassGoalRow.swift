import SathiCore
import SwiftUI

struct GlassGoalRow: View {
    @Binding var goal: Double

    private static let glasses = Array(1 ... Int(Limits.dailyGoalGlasses.upperBound))

    var body: some View {
        HStack(spacing: UIMetrics.sectionSpacing) {
            goalButton("−", label: "Fewer glasses", to: goal - 1)
            HStack(spacing: UIMetrics.glassSpacing) {
                ForEach(Self.glasses, id: \.self) { i in
                    GlassShape()
                        .fill(Double(i) <= goal ? Night.water : Night.switchOff)
                        .frame(width: UIMetrics.glassIconSize.width, height: UIMetrics.glassIconSize.height)
                }
            }
            .accessibilityHidden(true)
            goalButton("+", label: "More glasses", to: goal + 1)
            Spacer(minLength: 0)
            VStack(spacing: 0) {
                Text(verbatim: "\(Int(goal))")
                    .font(Typography.bigNumber)
                    .foregroundStyle(Night.text)
                Text(verbatim: "glasses")
                    .font(Typography.hint)
                    .foregroundStyle(Night.muted)
                    .fixedSize()
            }
        }
        .padding(UIMetrics.rowPadding)
    }

    private func goalButton(_ symbol: String, label: String, to target: Double) -> some View {
        let range = Limits.dailyGoalGlasses
        let next = min(max(target, range.lowerBound), range.upperBound)
        return RoundStepButton(symbol: symbol, label: label, enabled: next != goal) { goal = next }
    }
}

struct GlassShape: Shape {
    func path(in rect: CGRect) -> Path {
        let inset = rect.width * UIMetrics.glassTaper
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + inset, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
