import SathiCore
import SwiftUI

struct BuddyTotalsRow: View {
    let totals: [BuddyRangeTotal]
    let kind: ReportRange
    @Binding var selected: HabitID?

    var body: some View {
        HStack(alignment: .top, spacing: UIMetrics.tileGap) {
            ForEach(totals) { total in
                BuddyTotalCard(total: total, kind: kind, isSelected: selected == total.habit) {
                    selected = selected == total.habit ? nil : total.habit
                }
            }
        }
    }
}
