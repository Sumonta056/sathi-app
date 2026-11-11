import SwiftUI

struct AboutFooter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MadeByFooter()
            Text(verbatim: Self.versionText)
                .font(Typography.hint)
                .foregroundStyle(Night.faint)
                .padding(.horizontal, UIMetrics.navPadding.leading)
        }
    }

    static var version: String? {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }

    static var versionText: String {
        guard let version else { return "Sathi" }
        return "Sathi \(version)"
    }
}
