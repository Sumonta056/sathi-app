import SwiftUI

struct PillButton: ButtonStyle {
    enum Kind { case primary, ghost, onDark, danger }
    var kind: Kind = .primary
    var height: CGFloat = 44

    func makeBody(configuration: Configuration) -> some View {
        let (fg, bg) = colors
        return configuration.label
            .font(.system(size: 14, weight: .semibold))
            .lineLimit(1)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: height)
            .foregroundStyle(fg)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(bg))
            .opacity(configuration.isPressed ? 0.8 : 1)
            .contentShape(Rectangle())
    }

    private var colors: (Color, Color) {
        switch kind {
        case .primary: return (.white, Palette.go)
        case .ghost: return (Palette.ink, Palette.ink.opacity(0.07))
        case .onDark: return (Palette.waterDeep, .white)
        case .danger: return (Palette.danger, Color.white.opacity(0.1))
        }
    }
}
