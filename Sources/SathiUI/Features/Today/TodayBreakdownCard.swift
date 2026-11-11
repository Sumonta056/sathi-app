import SathiCore
import SwiftUI

struct TodayBreakdownCard: View {
    let sofar: TodaySoFar
    let categories: [ActivityCategory]

    var body: some View {
        let table = CategoryTable(sofar.categories.map(input))
        VStack(alignment: .leading, spacing: UIMetrics.todayBreakdownGap) {
            Text(verbatim: Copywriter.todayBreakdownTitle)
                .font(Typography.tracker(UIMetrics.todayPanelTitleFont, .heavy))
                .foregroundStyle(Night.text)
            if sofar.isOn {
                CategoryTableView(
                    table: table, summary: Copywriter.todayCategoryCount(table.rows.count), columns: 2, showsChange: false
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
        let hex = categories.first(where: { total.isNamed && $0.name == total.name })?.colorHex ?? UIMetrics.todayUnnamedHex
        return CategoryTableInput(name: total.name, colorHex: hex, seconds: total.seconds)
    }
}
