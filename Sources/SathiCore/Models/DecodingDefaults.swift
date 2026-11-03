import Foundation

extension KeyedDecodingContainer {
    func value<T: Decodable>(_ key: Key, or fallback: T) throws -> T {
        try decodeIfPresent(T.self, forKey: key) ?? fallback
    }

    func lenient<T: Decodable>(_ key: Key, or fallback: T) -> T {
        (try? decodeIfPresent(T.self, forKey: key)) ?? fallback
    }

    func known<T: RawRepresentable>(_ key: Key, or fallback: T) throws -> T where T.RawValue: Decodable {
        try decodeIfPresent(T.RawValue.self, forKey: key).flatMap(T.init(rawValue:)) ?? fallback
    }

    func knownSet<T: RawRepresentable & Hashable>(_ key: Key, or fallback: Set<T>, keepsEmpty: Bool) throws -> Set<T>
        where T.RawValue: Decodable {
        guard let raw = try decodeIfPresent([T.RawValue].self, forKey: key) else { return fallback }
        if raw.isEmpty { return keepsEmpty ? [] : fallback }
        let known = Set(raw.compactMap(T.init(rawValue:)))
        return known.isEmpty ? fallback : known
    }
}

extension KeyedDecodingContainer {
    func lenientSet<T: Decodable & Hashable>(_ key: Key, or fallback: Set<T>) -> Set<T> {
        guard let items = (try? decodeIfPresent([Lenient<T>].self, forKey: key)) ?? nil else { return fallback }
        return Set(items.compactMap(\.value))
    }

    func lenientArray<T: Decodable>(_ key: Key) -> [T] {
        ((try? decodeIfPresent([Lenient<T>].self, forKey: key)) ?? nil)?.compactMap(\.value) ?? []
    }
}

private struct Lenient<T: Decodable>: Decodable {
    let value: T?

    init(from decoder: Decoder) throws {
        value = try? T(from: decoder)
    }
}
