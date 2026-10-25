import SathiCore
import SwiftUI

struct ReportsHeader: View {
    let screen: ReportScreen
    @Binding var range: ReportRange

    var body: some View {
        HStack(alignment: .center, spacing: UIMetrics.reportsGap) {
            VStack(alignment: .leading, spacing: UIMetrics.textSpacing) {
                Text(verbatim: screen.headline)
                    .font(Typography.heroTitle)
                    .foregroundStyle(Night.text)
                Text(verbatim: screen.subline)
                    .font(Typography.hint)
                    .foregroundStyle(Night.muted)
            }
            Spacer(minLength: 0)
            RangeSegment(range: $range)
        }
    }
}
