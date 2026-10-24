import Foundation

package func makeTempFolder() -> URL {
    FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
}

package func fileExists(_ url: URL) -> Bool {
    FileManager.default.fileExists(atPath: url.path)
}

package func readText(_ url: URL) -> String? {
    try? String(contentsOf: url, encoding: .utf8)
}

package func writeText(_ text: String, to url: URL) throws {
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data(text.utf8).write(to: url)
}

package func readJSONObject(_ url: URL) -> [String: Any]? {
    guard let data = try? Data(contentsOf: url) else { return nil }
    return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
}

package func readData(_ url: URL) -> Data? {
    try? Data(contentsOf: url)
}

package func setPermissions(_ mode: Int, _ url: URL) throws {
    try FileManager.default.setAttributes([.posixPermissions: mode], ofItemAtPath: url.path)
}

package func makeFolder(_ url: URL) throws {
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
}
