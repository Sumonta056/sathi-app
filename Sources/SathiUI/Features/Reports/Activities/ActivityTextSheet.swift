import SathiCore
import SwiftUI

struct ActivityTextSheet: View {
    let title: String
    let text: String
    let copyLabel: String
    var copy: (String) -> Void = ActivityPasteboard.copy
    let close: () -> Void
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.activitiesSheetGap) {
            Text(verbatim: title).font(Typography.rowLabel).foregroundStyle(Night.text)
            ScrollView {
                Text(verbatim: text)
                    .font(Typography.hint)
                    .foregroundStyle(Night.muted)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(UIMetrics.trackerTextBoxPadding)
            }
            .frame(height: UIMetrics.activitiesSheetTextHeight)
            .background(RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous).fill(Night.bg))
            HStack(spacing: UIMetrics.reportsGap) {
                Spacer(minLength: 0)
                Button(Copywriter.activitiesClose, action: close)
                    .buttonStyle(GhostButton(accent: Night.tracker, height: UIMetrics.trackerMiniButton))
                Button(copied ? Copywriter.trackerCopied : copyLabel) {
                    copy(text)
                    copied = true
                }
                .buttonStyle(GhostButton(accent: Night.tracker, height: UIMetrics.trackerMiniButton))
            }
        }
        .padding(UIMetrics.activitiesSheetPadding)
        .frame(width: UIMetrics.activitiesSheetWidth)
        .background(Night.card)
    }
}
