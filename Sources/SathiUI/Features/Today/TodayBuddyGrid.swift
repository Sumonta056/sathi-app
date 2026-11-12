import SathiCore
import SwiftUI

struct TodayBuddyGrid: View {
    let e: Engine
    let buddies: [TodayBuddy]
    let calendar: Calendar

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: UIMetrics.todayGridGap, alignment: .top), count: UIMetrics.todayBuddyColumns),
            spacing: UIMetrics.todayGridGap
        ) {
            ForEach(buddies) { TodayBuddyCard(e: e, buddy: $0, calendar: calendar) }
        }
    }
}
