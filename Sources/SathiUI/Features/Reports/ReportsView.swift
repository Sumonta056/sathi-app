import SathiCore
import SwiftUI

struct ReportsView: View {
    @EnvironmentObject var e: Engine
    @State private var activityRange = ActivityRange.day
    @State private var activityDay: DayKey?

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.reportsGap) {
            HStack {
                Spacer(minLength: 0)
                PillSegment(options: ActivityRange.allCases, selected: $activityRange, title: \.title)
            }
            ActivityReportsView(range: $activityRange, day: $activityDay)
        }
        .padding(UIMetrics.reportsPadding)
        .padding(.top, UIMetrics.titleBarInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Night.bg)
        .ignoresSafeArea()
        .onAppear(perform: openAskedDay)
        .onChange(of: e.activityReportDay) { _ in openAskedDay() }
    }

    private func openAskedDay() {
        guard let asked = e.takeActivityReportDay() else { return }
        activityRange = .day
        activityDay = asked
    }
}
