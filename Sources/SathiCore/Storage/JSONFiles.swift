import Foundation

struct Versioned<T: Codable>: Codable {
    var schemaVersion: Int
    var value: T
}

enum LoadResult<T> {
    case missing
    case value(T)
    case unreadable
}

enum JSONFiles {
    static func encoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.sortedKeys]
        return e
    }

    static func decoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    static func load<T: Codable>(_ type: T.Type, from url: URL) -> LoadResult<T> {
        guard FileManager.default.fileExists(atPath: url.path) else { return .missing }
        guard let data = try? Data(contentsOf: url) else { return .unreadable }
        if let decoded = try? decoder().decode(Versioned<T>.self, from: data) { return .value(decoded.value) }
        return quarantine(url) ? .missing : .unreadable
    }

    static func write(_ value: some Codable, to url: URL) -> Bool {
        guard let data = try? encoder().encode(Versioned(schemaVersion: Limits.schemaVersion, value: value)) else { return false }
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    private static func quarantine(_ url: URL) -> Bool {
        let target = url.deletingLastPathComponent().appendingPathComponent(url.lastPathComponent + StorageKeys.corruptSuffix)
        return rename(url.path, target.path) == 0
    }
}
