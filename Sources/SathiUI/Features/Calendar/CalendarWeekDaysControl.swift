import SathiCore
import SwiftUI

struct CalendarWeekDaysControl: View {
    let days: Int
    let pick: (Int) -> Void

    var body: some View {
        PillSegment(options: Limits.calendarWeekDays, selected: selected, title: Copywriter.calendarWeekDaysOption)
            .fixedSize()
    }

    private var selected: Binding<Int> {
        Binding(get: { days }, set: { pick($0) })
    }
}
