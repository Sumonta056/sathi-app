import SathiCore
import SwiftUI

struct DashboardPage: View {
    @EnvironmentObject var e: Engine
    let kind: ReportRange

    var body: some View {
        switch kind {
        case .day: TodayPage()
        case .week, .month: ReportsPage(range: e.currentRange(kind))
        }
    }
}
