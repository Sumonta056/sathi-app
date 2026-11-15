import SathiCore
import SwiftUI

struct TodayBuddyGrid: View {
    let e: Engine
    let buddies: [TodayBuddy]
    let calendar: Calendar
    @Environment(\.mainLayout) private var layout

    static func columnCount(_ layout: MainLayout) -> Int {
        layout.isNarrow ? UIMetrics.todayBuddyColumnsNarrow : UIMetrics.todayBuddyColumns
    }

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: UIMetrics.todayGridGap, alignment: .top), count: Self.columnCount(layout)),
            spacing: UIMetrics.todayGridGap
        ) {
            ForEach(buddies) { TodayBuddyCard(e: e, buddy: $0, calendar: calendar) }
        }
    }
}
