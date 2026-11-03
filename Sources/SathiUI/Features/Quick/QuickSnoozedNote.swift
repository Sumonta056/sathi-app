import SathiCore
import SwiftUI

struct QuickSnoozedNote: View {
    @EnvironmentObject var e: Engine
    let text: String
    let until: Date

    var body: some View {
        HStack(spacing: UIMetrics.quickNoteSpacing) {
            Image(systemName: "bell")
                .font(.system(size: UIMetrics.quickNoteIcon, weight: .semibold))
                .foregroundStyle(Night.quick)
            Text(verbatim: Copywriter.quickComesBack(text: text, at: until, calendar: Calendar.gregorian(in: e.timeZone)))
                .font(Typography.hint)
                .foregroundStyle(Night.chipText)
        }
        .padding(UIMetrics.notePadding)
        .background(Capsule().fill(Night.card))
        .overlay(Capsule().strokeBorder(Night.quickBorder, lineWidth: UIMetrics.bubbleBorder))
        .padding(UIMetrics.bubbleShadowPadding)
        .environment(\.colorScheme, .dark)
    }
}
