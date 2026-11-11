import SwiftUI

struct ReportsRing<Label: View>: View {
    let fraction: Double
    let color: Color
    let size: CGFloat
    let line: CGFloat
    @ViewBuilder let label: () -> Label

    var body: some View {
        ZStack {
            Circle().stroke(Night.divider, lineWidth: line)
            Circle()
                .trim(from: 0, to: min(max(fraction, 0), 1))
                .stroke(color, style: StrokeStyle(lineWidth: line, lineCap: .butt))
                .rotationEffect(.degrees(-90))
            label()
        }
        .padding(line / 2)
        .frame(width: size, height: size)
    }

    static func fraction(_ part: Int, of whole: Int) -> Double {
        whole > 0 ? Double(part) / Double(whole) : 0
    }
}
