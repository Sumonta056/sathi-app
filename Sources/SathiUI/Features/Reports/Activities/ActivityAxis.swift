import SathiCore
import SwiftUI

struct ActivityAxis: View {
    let hours: DateInterval
    let calendar: Calendar
    var nowAt: CGFloat?

    var body: some View {
        GeometryReader { g in
            let label = nowAt.map { Self.labelX(width: g.size.width, fraction: $0) }
            ForEach(Self.marks(hours, calendar: calendar), id: \.self) { date in
                let x = g.size.width * CGFloat(date.timeIntervalSince(hours.start) / max(hours.duration, 1))
                Text(verbatim: "\(calendar.component(.hour, from: date))")
                    .font(Typography.hint)
                    .foregroundStyle(Night.faint)
                    .opacity(Self.hides(markX: x, labelX: label) ? 0 : 1)
                    .position(x: x, y: UIMetrics.trackerAxisHeight / 2)
            }
        }
        .frame(height: UIMetrics.trackerAxisHeight)
    }

    static func labelX(width: CGFloat, fraction: CGFloat) -> CGFloat {
        min(max(width * fraction, UIMetrics.todayNowLabelHalfWidth), width - UIMetrics.todayNowLabelHalfWidth)
    }

    static func hides(markX: CGFloat, labelX: CGFloat?) -> Bool {
        guard let labelX else { return false }
        return abs(markX - labelX) <= UIMetrics.todayNowLabelHalfWidth + UIMetrics.trackerAxisMarkHalfWidth
    }

    static func marks(_ hours: DateInterval, calendar: Calendar) -> [Date] {
        guard hours.duration > 0 else { return [] }
        var result: [Date] = []
        var cursor = calendar.nextDate(
            after: hours.start.addingTimeInterval(-Timing.second),
            matching: DateComponents(minute: 0),
            matchingPolicy: .nextTime
        )
        while let d = cursor, d <= hours.end {
            result.append(d)
            cursor = calendar.date(byAdding: .hour, value: 1, to: d)
        }
        return result
    }
}
