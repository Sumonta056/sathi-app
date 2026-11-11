import SathiCore
import SwiftUI

struct SettingsHeader: View {
    @EnvironmentObject var e: Engine
    let page: SettingsPage

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: UIMetrics.textSpacing) {
                Text(verbatim: Copywriter.settingsEyebrow)
                    .font(Typography.eyebrow)
                    .tracking(UIMetrics.labelTracking)
                    .foregroundStyle(Night.muted)
                Text(verbatim: Copywriter.settingsHeaderTitle(page))
                    .font(Typography.tracker(UIMetrics.mainPageTitleFont, .heavy))
                    .foregroundStyle(Night.text)
            }
            Spacer(minLength: 0)
            if case let .habit(id) = page {
                HStack(spacing: UIMetrics.sectionSpacing) {
                    Text(verbatim: Copywriter.settingsOn)
                        .font(Typography.rowLabel)
                        .foregroundStyle(Night.label)
                    BuddySwitch(isOn: e.enabledBinding(id), accent: Night.accent(id), label: Copywriter.settingsOnLabel(id))
                }
            }
        }
    }
}
