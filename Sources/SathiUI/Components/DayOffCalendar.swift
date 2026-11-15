import SathiCore
import SwiftUI

struct DayOffCalendar: View {
    let make: @MainActor (Engine) -> DaysOffSource
    let accent: Color
    @Binding var offset: Int
    @EnvironmentObject var e: Engine

    init(make: @escaping @MainActor (Engine) -> DaysOffSource, accent: Color, offset: Binding<Int>) {
        self.make = make
        self.accent = accent
        _offset = offset
    }

    init(habit: HabitID, accent: Color, offset: Binding<Int>) {
        self.init(make: { DaysOffSource.habit(habit, $0) }, accent: accent, offset: offset)
    }

    var body: some View {
        MonthDayGrid(month: make(e).month(offset), accent: accent, offset: $offset, markedValue: Copywriter.daysOffMarked) {
            make(e).add($0)
        }
    }
}
