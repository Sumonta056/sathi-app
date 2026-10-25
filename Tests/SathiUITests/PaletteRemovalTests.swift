import Foundation
import Testing

@Suite("Palette removal")
struct PaletteRemovalTests {
    private static let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    private static var sources: URL { root.appendingPathComponent("Sources") }

    private static func swiftFiles() -> [URL] {
        let e = FileManager.default.enumerator(at: sources, includingPropertiesForKeys: nil)
        return (e?.allObjects as? [URL] ?? []).filter { $0.pathExtension == "swift" }
    }

    @Test func sourcesFolderIsFound() {
        #expect(!Self.swiftFiles().isEmpty)
    }

    @Test func oldPaletteFileIsDeleted() {
        let path = Self.sources.appendingPathComponent("SathiUI/Theme/Palette.swift").path
        #expect(!FileManager.default.fileExists(atPath: path))
    }

    @Test func noSourceUsesTheOldPalette() throws {
        let users = try Self.swiftFiles()
            .filter { try String(contentsOf: $0, encoding: .utf8).contains("Palette.") }
            .map { $0.path.replacingOccurrences(of: Self.root.path + "/", with: "") }
            .sorted()
        #expect(users.isEmpty, "Palette. still used in \(users)")
    }
}
