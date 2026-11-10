import SathiCore
import SwiftUI

struct ActivityAxis: View {
    let hours: DateInterval
    let calendar: Calendar

    var body: some View {
        GeometryReader { g in
            ForEach(Self.marks(hours, calendar: calendar), id: \.self) { date in
                Text(verbatim: "\(calendar.component(.hour, from: date))")
                    .font(Typography.hint)
                    .foregroundStyle(Night.faint)
                    .position(
                        x: g.size.width * CGFloat(date.timeIntervalSince(hours.start) / max(hours.duration, 1)),
                        y: UIMetrics.trackerAxisHeight / 2
                    )
            }
        }
        .frame(height: UIMetrics.trackerAxisHeight)
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
