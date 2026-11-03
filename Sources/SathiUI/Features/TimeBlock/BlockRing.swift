import SathiCore
import SwiftUI

struct BlockRing: View {
    let progress: Double
    var size: CGFloat = UIMetrics.ringSize
    var line: CGFloat = UIMetrics.blockRingLine

    var body: some View {
        ZStack {
            Circle().stroke(Night.blockBorder, lineWidth: line)
            Circle()
                .trim(from: 0, to: ProgressRing.clamp(progress))
                .stroke(Night.block, style: StrokeStyle(lineWidth: line, lineCap: .round))
                .rotationEffect(.degrees(UIMetrics.ringStartAngle))
        }
        .padding(line / 2)
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityValue(ProgressRing.percent(progress))
    }

    static func progress(_ block: TimeBlock, now: Date) -> Double {
        guard let end = block.plannedEnd else { return 0 }
        let total = end.timeIntervalSince(block.startedAt)
        return total > 0 ? max(0, now.timeIntervalSince(block.startedAt)) / total : 0
    }
}
