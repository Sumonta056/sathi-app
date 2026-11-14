import SwiftUI

struct ExperimentalTag: View {
    let text: String

    var body: some View {
        Text(verbatim: text)
            .font(Typography.tracker(UIMetrics.calendarTagFont, .bold))
            .foregroundStyle(Night.spark)
            .padding(UIMetrics.calendarTagPadding)
            .overlay(
                Capsule().strokeBorder(Night.spark.opacity(UIMetrics.calendarTagBorderOpacity), lineWidth: UIMetrics.calendarTagBorder)
            )
            .fixedSize()
    }
}
