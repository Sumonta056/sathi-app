import SwiftUI

struct SettingsSubtitle: View {
    let text: String

    var body: some View {
        Text(verbatim: text)
            .font(Typography.hint)
            .foregroundStyle(Night.muted)
    }
}
