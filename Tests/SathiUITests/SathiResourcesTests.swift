import Foundation
@testable import SathiUI
import Testing

@Suite("Sathi resources")
struct SathiResourcesTests {
    @Test func findsBundledFontsFile() {
        #expect(SathiResources.url("OFL", ext: "txt", in: .fonts) != nil)
    }

    @Test func missingFileGivesNil() {
        #expect(SathiResources.url("does-not-exist", ext: "mp3", in: .audio) == nil)
    }
}
