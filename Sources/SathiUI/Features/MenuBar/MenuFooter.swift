import AppKit
import SathiCore
import SwiftUI

struct MenuFooter: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        VStack(spacing: UIMetrics.footerPadding) {
            Rectangle()
                .fill(Night.divider)
                .frame(height: UIMetrics.dividerHeight)
            HStack {
                icon("chart.bar.fill", "Reports") {
                    MenuBarWindow.close()
                    e.openReports()
                }
                icon("gearshape.fill", "Settings") {
                    MenuBarWindow.close()
                    e.openSettings()
                }
                Spacer()
                Text(Self.versionText)
                    .font(Typography.hint)
                    .foregroundStyle(Night.faint)
                Spacer()
                icon("power", "Quit Sathi") { NSApp.terminate(nil) }
            }
        }
    }

    static var versionText: String {
        guard let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else { return "Sathi" }
        return "Sathi \(v)"
    }

    private func icon(_ symbol: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: UIMetrics.footerIconSize, weight: .bold))
                .frame(width: UIMetrics.footerButtonSize, height: UIMetrics.footerButtonSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(Night.muted)
        .accessibilityLabel(label)
    }
}
