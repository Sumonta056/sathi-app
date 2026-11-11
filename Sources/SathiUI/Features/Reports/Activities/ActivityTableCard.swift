import SathiCore
import SwiftUI

struct ActivityTableCard: View {
    let table: CategoryTable

    var body: some View {
        ReportsCard {
            CategoryTableView(table: table, summary: "logged · " + Copywriter.categoryCount(table.rows.count), columns: 2, showsChange: false)
        }
    }

    static func day(_ totals: [ActivityCategoryTotal], categories: [ActivityCategory]) -> CategoryTable {
        CategoryTable(totals.map {
            CategoryTableInput(name: $0.name, colorHex: ActivityColors.hex($0.isNamed ? $0.name : nil, in: categories), seconds: $0.seconds)
        })
    }

    static func range(_ totals: [ActivityRangeTotal], categories: [ActivityCategory]) -> CategoryTable {
        CategoryTable(totals.compactMap { t in
            switch t.kind {
            case .away: return nil
            case .events: return CategoryTableInput(name: t.name, colorHex: NightHex.trackerEvent, seconds: t.seconds)
            case .category:
                return CategoryTableInput(name: t.name, colorHex: ActivityColors.hex(t.isNamed ? t.name : nil, in: categories), seconds: t.seconds)
            }
        })
    }
}
