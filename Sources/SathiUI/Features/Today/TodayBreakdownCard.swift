import SathiCore
import SwiftUI

struct TodayBreakdownCard: View {
    let sofar: TodaySoFar
    let categories: [ActivityCategory]
    @Environment(\.mainLayout) private var layout

    var body: some View {
        let table = CategoryTable(sofar.categories.map(input))
        VStack(alignment: .leading, spacing: UIMetrics.todayBreakdownGap) {
            Text(verbatim: Copywriter.todayBreakdownTitle)
                .font(Typography.tracker(UIMetrics.todayPanelTitleFont, .heavy))
                .foregroundStyle(Night.text)
            if sofar.isOn {
                CategoryTableView(
                    table: table, summary: Copywriter.categoryCount(table.rows.count),
                    columns: layout.isNarrow ? UIMetrics.todayBreakdownColumnsNarrow : 2, showsChange: false, showsTotal: false
                )
            } else {
                Text(verbatim: Copywriter.todaySoFarOffHint)
                    .font(Typography.tracker(UIMetrics.todayPanelNoteFont, .regular))
                    .foregroundStyle(Night.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(UIMetrics.todayPanelPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .todayCard()
    }

    private func input(_ total: ActivityCategoryTotal) -> CategoryTableInput {
        CategoryTableInput(name: total.name, colorHex: ActivityColors.hex(total.isNamed ? total.name : nil, in: categories), seconds: total.seconds)
    }
}
