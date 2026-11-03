import SathiCore
import SwiftUI

struct WeekdayRow: View {
    let habit: HabitID
    @EnvironmentObject var e: Engine

    var body: some View {
        let days = e.weekdays(habit)
        ChipRow(
            options: Weekday.allCases,
            accent: Night.accent(habit),
            isSelected: { days.wrappedValue.contains($0) },
            onTap: { days.wrappedValue = days.wrappedValue.togglingKeepingOne($0) },
            label: \.shortLabel,
            spokenLabel: \.name
        )
    }
}
