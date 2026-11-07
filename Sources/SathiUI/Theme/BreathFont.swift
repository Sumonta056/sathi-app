import CoreText
import SwiftUI

enum BreathFace {
    case light, regular, medium, semibold

    var weight: Font.Weight {
        switch self {
        case .light: .light
        case .regular: .regular
        case .medium: .medium
        case .semibold: .semibold
        }
    }
}

enum BreathFont {
    static let family = "Figtree"
    static let file = "Figtree-Variable"
    static let ext = "ttf"
    static let isRegistered: Bool = register()

    static func font(_ face: BreathFace, size: CGFloat) -> Font {
        guard isRegistered else { return .system(size: size, weight: face.weight, design: .rounded) }
        return .custom(family, size: size).weight(face.weight)
    }

    private static func register() -> Bool {
        guard let url = SathiResources.url(file, ext: ext, in: .fonts) else { return false }
        var error: Unmanaged<CFError>?
        if CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) { return true }
        let code = error.map { CFErrorGetCode($0.takeRetainedValue()) }
        return code == CTFontManagerError.alreadyRegistered.rawValue
    }
}
