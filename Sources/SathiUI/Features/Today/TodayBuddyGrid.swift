import SathiCore
import SwiftUI

struct TodayBuddyGrid: View {
    let buddies: [TodayBuddy]
    let calendar: Calendar

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: UIMetrics.todayGridGap, alignment: .top), count: UIMetrics.todayBuddyColumns),
            spacing: UIMetrics.todayGridGap
        ) {
            ForEach(buddies) { TodayBuddyCard(buddy: $0, calendar: calendar) }
        }
    }
}
