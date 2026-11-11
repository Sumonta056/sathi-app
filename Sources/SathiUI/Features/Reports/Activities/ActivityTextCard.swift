import SathiCore
import SwiftUI

struct ActivityTextCard: View {
    let title: String
    let text: String
    let copy: (String) -> Void
    @State private var copied = false

    var body: some View {
        ReportsCard {
            HStack {
                Text(verbatim: title).font(Typography.rowLabel).foregroundStyle(Night.text)
                Spacer(minLength: 0)
                Button(copied ? Copywriter.trackerCopied : Copywriter.activitiesCopy) {
                    copy(text)
                    copied = true
                }
                .buttonStyle(GhostButton(accent: Night.tracker, height: UIMetrics.trackerMiniButton))
            }
            Text(verbatim: text)
                .font(Typography.hint)
                .foregroundStyle(Night.muted)
                .lineLimit(UIMetrics.activitiesTextLines)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(UIMetrics.trackerTextBoxPadding)
                .background(RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous).fill(Night.bg))
        }
    }
}
