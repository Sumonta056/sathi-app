import SwiftUI

struct CalendarColumnWidth: View {
    let days: Int
    let measured: (CGFloat) -> Void

    var body: some View {
        GeometryReader { geo in
            let width = Self.column(total: geo.size.width, days: days)
            Color.clear
                .onAppear { measured(width) }
                .onChange(of: width) { measured($0) }
        }
    }

    static func column(total: CGFloat, days: Int) -> CGFloat {
        max(0, total - UIMetrics.calendarHourLabelWidth) / CGFloat(max(1, days))
    }
}
