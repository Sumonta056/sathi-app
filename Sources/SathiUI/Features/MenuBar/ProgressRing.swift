import SathiCore
import SwiftUI

struct ProgressRing: View {
    let progress: Double
    let accent: Color

    var body: some View {
        ZStack {
            Circle().stroke(Night.border, lineWidth: UIMetrics.ringLine)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(accent, style: StrokeStyle(lineWidth: UIMetrics.ringLine, lineCap: .round))
                .rotationEffect(.degrees(UIMetrics.ringStartAngle))
        }
        .padding(UIMetrics.ringLine / 2)
        .frame(width: UIMetrics.ringSize, height: UIMetrics.ringSize)
        .accessibilityElement(children: .ignore)
        .accessibilityValue(Self.percent(progress))
    }

    private var clamped: Double { Self.clamp(progress) }

    static func clamp(_ value: Double) -> Double { min(1, max(0, value)) }

    static func percent(_ value: Double) -> String {
        "\(Int((clamp(value) * Double(Limits.fullPercent)).rounded()))%"
    }
}
