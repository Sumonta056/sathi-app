import Foundation

extension Engine {
    static func freeURL(in folder: URL, name: String) -> URL {
        let first = folder.appendingPathComponent(name)
        guard FileManager.default.fileExists(atPath: first.path) else { return first }
        let base = first.deletingPathExtension().lastPathComponent
        let ext = first.pathExtension
        var n = Limits.firstCopyNumber
        while true {
            let url = folder.appendingPathComponent("\(base) (\(n))").appendingPathExtension(ext)
            if !FileManager.default.fileExists(atPath: url.path) { return url }
            n += 1
        }
    }
}
