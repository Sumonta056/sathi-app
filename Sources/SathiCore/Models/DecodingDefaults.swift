import Foundation

extension KeyedDecodingContainer {
    func value<T: Decodable>(_ key: Key, or fallback: T) throws -> T {
        try decodeIfPresent(T.self, forKey: key) ?? fallback
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
