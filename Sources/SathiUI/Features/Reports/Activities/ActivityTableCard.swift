import SathiCore
import SwiftUI

struct ActivityTableCard: View {
    let table: CategoryTable

    var body: some View {
        ReportsCard {
            CategoryTableView(table: table, summary: "logged · " + Copywriter.categoryCount(table.categoryRowCount), columns: 2, showsChange: false)
        }
    }

    static func day(_ totals: [ActivityCategoryTotal], away: [ActivityCategoryTotal] = [], categories: [ActivityCategory]) -> CategoryTable {
        CategoryTable(totals.map {
            CategoryTableInput(name: $0.name, colorHex: ActivityColors.hex($0.isNamed ? $0.name : nil, in: categories), seconds: $0.seconds)
        } + away.map { awayInput($0.name, $0.seconds) })
    }

    static func range(_ totals: [ActivityRangeTotal], categories: [ActivityCategory]) -> CategoryTable {
        CategoryTable(totals.map { t in
            switch t.kind {
            case .away: return awayInput(t.name, t.seconds)
            case .events: return CategoryTableInput(name: t.name, colorHex: NightHex.trackerEvent, seconds: t.seconds)
            case .category:
                return CategoryTableInput(name: t.name, colorHex: ActivityColors.hex(t.isNamed ? t.name : nil, in: categories), seconds: t.seconds)
            }
        })
    }

    private static func awayInput(_ place: String, _ seconds: TimeInterval) -> CategoryTableInput {
        CategoryTableInput(name: Copywriter.categoryTableAwayRow(place), colorHex: NightHex.trackerAway, seconds: seconds, isAway: true)
    }
}
