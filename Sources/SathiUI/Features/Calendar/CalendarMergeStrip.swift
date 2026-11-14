import SathiCore
import SwiftUI

struct CalendarMergeStrip: View {
    let rows: [Activity]
    let calendar: Calendar
    let canUndo: Bool
    let actions: ActivityDayActions
    @Binding var selected: Set<ActivityID>
    @Binding var error: String?
    @State private var memo = ActivityMergeCheckMemo()

    var body: some View {
        if ActivityMergeBar.shows(selected: selected, canUndo: canUndo, error: error) {
            ActivityMergeBar(
                check: check, calendar: calendar, canUndo: canUndo,
                actions: actions, selected: $selected, error: $error
            )
        } else {
            Text(verbatim: Copywriter.calendarMergeHint)
                .font(Typography.hint)
                .foregroundStyle(Night.faint)
        }
    }

    private var check: ManualMergeCheck? {
        guard !selected.isEmpty else { return nil }
        return memo.value(selected, rows: rows, make: actions.mergeCheck)
    }
}
