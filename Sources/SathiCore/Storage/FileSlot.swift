import Foundation

struct FileSlot<T: Codable> {
    let url: URL
    var pending: T?
    private var probed = false
    private var blocked = false

    init(url: URL) {
        self.url = url
    }

    mutating func load() -> T? {
        if let pending { return pending }
        return read()
    }

    mutating func write() -> Bool {
        guard let value = pending else { return true }
        if !probed { _ = read() }
        guard !blocked, JSONFiles.write(value, to: url) else { return false }
        pending = nil
        return true
    }

    private mutating func read() -> T? {
        guard !blocked else { return nil }
        probed = true
        switch JSONFiles.load(T.self, from: url) {
        case .missing: return nil
        case let .value(v): return v
        case .unreadable:
            blocked = true
            return nil
        }
    }
}
