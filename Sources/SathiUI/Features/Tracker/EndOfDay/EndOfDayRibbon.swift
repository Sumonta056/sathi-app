import SathiCore
import SwiftUI

struct EndOfDayRibbon: View {
    let day: ActivityDay
    let stats: ActivityDayStats
    let categories: [ActivityCategory]
    let reduceMotion: Bool
    @State private var revealed = false

    var body: some View {
        ActivityRibbon(
            segments: stats.segments, hours: day.hours, categories: categories,
            reveal: EndOfDayAnimation.reveal(count: stats.segments.count, revealed: revealed || reduceMotion, reduceMotion: reduceMotion)
        )
        .onAppear { revealed = true }
    }
}
