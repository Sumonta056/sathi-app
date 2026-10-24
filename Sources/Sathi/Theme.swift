import SwiftUI

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

enum Palette {
    static let ink = Color(hex: 0x0D1B2A)
    static let ink2 = Color(hex: 0x3A4D60)
    static let muted = Color(hex: 0x566A7E)
    static let card = Color(hex: 0xF8FBFD)

    static let water = Color(hex: 0x1FA8E6)
    static let waterDeep = Color(hex: 0x0B5F9E)
    static let waterPale = Color(hex: 0xDCF2FC)
    static let waterMid = Color(hex: 0x7FD3F5)
    static let outline = Color(hex: 0x0B4F86)
    static let drip = Color(hex: 0x8FD8F7)

    static let book = Color(hex: 0xE0902A)
    static let bookDeep = Color(hex: 0x8A4B12)
    static let cover = Color(hex: 0xF2A33A)
    static let spine = Color(hex: 0xD9822B)
    static let pages = Color(hex: 0xFFF6E2)
    static let bookLine = Color(hex: 0x7A420F)
    static let ribbon = Color(hex: 0xE0473C)
    static let paper = Color(hex: 0xFFFAF1)

    static let go = Color(hex: 0x178A4F)
    static let cheek = Color(hex: 0xFF9FB8)
    static let spark = Color(hex: 0xFFC94A)
    static let night = Color(hex: 0x041A30)
}

struct PillButton: ButtonStyle {
    enum Kind { case primary, ghost, onDark, danger }
    var kind: Kind = .primary
    var height: CGFloat = 44

    func makeBody(configuration: Configuration) -> some View {
        let fg: Color
        let bg: Color
        switch kind {
        case .primary: fg = .white; bg = Palette.go
        case .ghost: fg = Palette.ink; bg = Palette.ink.opacity(0.07)
        case .onDark: fg = Palette.waterDeep; bg = .white
        case .danger: fg = Color(hex: 0xFFD2C2); bg = Color.white.opacity(0.1)
        }
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
}

struct MiniButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(configuration.isPressed ? 0.16 : 0.08)))
            .contentShape(Rectangle())
    }
}

struct ProgressBar: View {
    var value: Double
    var tint: Color
    var height: CGFloat = 6
    var track: Color = Color.primary.opacity(0.1)

    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule().fill(tint).frame(width: g.size.width * CGFloat(min(1, max(0, value))))
            }
        }
        .frame(height: height)
    }
}

struct Shake: GeometryEffect {
    var amount: CGFloat
    var animatableData: CGFloat {
        get { amount }
        set { amount = newValue }
    }
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 9 * sin(amount * .pi * 6), y: 0))
    }
}
