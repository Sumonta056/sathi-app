import SathiCore
import SwiftUI

struct BlockDefaultCalendarRow: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        HStack(alignment: .top, spacing: UIMetrics.blockSettingsColumnSpacing) {
            VStack(alignment: .leading, spacing: UIMetrics.textSpacing) {
                Text(verbatim: Copywriter.blockSettingsDefaultCalendar)
                    .font(Typography.rowLabel)
                    .foregroundStyle(Night.text)
                Text(verbatim: Copywriter.blockSettingsDefaultHint)
                    .font(Typography.hint)
                    .foregroundStyle(Night.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: UIMetrics.blockSettingsLabelWidth, alignment: .leading)
            if e.calendarAccess == .allowed {
                BlockDefaultCalendarList()
            } else {
                Text(verbatim: Copywriter.blockSettingsNeedsAccess)
                    .font(Typography.hint)
                    .foregroundStyle(Night.faint)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(UIMetrics.rowPadding)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Night.divider)
                .frame(height: UIMetrics.dividerHeight)
        }
    }
}
