import Foundation

package enum ResourceFolder: String {
    case fonts = "Fonts"
    case audio = "Audio"
}

package enum SathiResources {
    static let bundleName = "Sathi_SathiUI.bundle"
    static let innerPath = "Contents/Resources"

    private final class Anchor {}

    package static func url(_ name: String, ext: String, in folder: ResourceFolder) -> URL? {
        let file = "\(name).\(ext)"
        let beside = Bundle(for: Anchor.self).bundleURL.deletingLastPathComponent().appendingPathComponent(bundleName)
        let inMain = Bundle.main.bundleURL.appendingPathComponent(bundleName)
        let roots: [URL?] = [
            Bundle.main.resourceURL,
            inMain,
            inMain.appendingPathComponent(innerPath),
            beside,
            beside.appendingPathComponent(innerPath)
        ]
        for root in roots {
            guard let root else { continue }
            let candidate = root.appendingPathComponent(folder.rawValue).appendingPathComponent(file)
            if FileManager.default.fileExists(atPath: candidate.path) { return candidate }
        }
        return nil
    }
}
