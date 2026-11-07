import SathiCore
@testable import SathiUI
import SwiftUI
import Testing

@MainActor
@Suite("Breath font")
struct BreathFontTests {
    private var fileFound: Bool {
        SathiResources.url(BreathFont.file, ext: BreathFont.ext, in: .fonts) != nil
    }

    @Test func registersOnlyWhenTheFileIsThere() {
        #expect(BreathFont.isRegistered == fileFound)
    }

    @Test func lightUsesFigtreeOrFallsBackToRounded() {
        let font = BreathFont.font(.light, size: 34)
        let figtree = Font.custom(BreathFont.family, size: 34).weight(.light)
        let system = Font.system(size: 34, weight: .light, design: .rounded)
        #expect(font == (BreathFont.isRegistered ? figtree : system))
    }

    @Test(arguments: [
        (BreathFace.light, Font.Weight.light),
        (.regular, .regular),
        (.medium, .medium),
        (.semibold, .semibold)
    ])
    func facesMapToWeights(_ face: BreathFace, _ weight: Font.Weight) {
        #expect(face.weight == weight)
    }
}
