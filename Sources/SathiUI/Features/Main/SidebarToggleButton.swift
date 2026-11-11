import SathiCore
import SwiftUI

struct SidebarToggleButton: View {
    let isOpen: Bool
    let size: CGSize
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            Image(systemName: "sidebar.left")
                .font(.system(size: UIMetrics.sidebarToggleIcon, weight: .semibold))
                .foregroundStyle(Night.muted)
                .frame(width: size.width, height: size.height)
                .background(RoundedRectangle(cornerRadius: UIMetrics.sidebarToggleRadius, style: .continuous).fill(Night.card))
                .overlay(RoundedRectangle(cornerRadius: UIMetrics.sidebarToggleRadius, style: .continuous).stroke(Night.border))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label)
    }

    private var label: String {
        isOpen ? Copywriter.sidebarCloseLabel : Copywriter.sidebarOpenLabel
    }
}
