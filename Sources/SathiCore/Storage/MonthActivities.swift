import Foundation

struct MonthActivities: Codable {
    var items: [Activity]
    var extras: [ActivityID: [String: RawJSON]]
    var unknown: [RawJSON]

    init(items: [Activity], extras: [ActivityID: [String: RawJSON]], unknown: [RawJSON]) {
        self.items = items
        self.extras = extras
        self.unknown = unknown
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        let raw = try c.decode([RawJSON].self)
        let parsed = try c.decode([MaybeActivity].self)
        items = []
        extras = [:]
        unknown = []
        for (value, maybe) in zip(raw, parsed) {
            if let item = maybe.value, case let .object(fields) = value {
                let known = try item.rawFields()
                items.append(item)
                extras[item.id] = fields.filter { known[$0.key] == nil }
            } else {
                unknown.append(value)
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.unkeyedContainer()
        for item in items {
            let extra = extras[item.id] ?? [:]
            try c.encode(RawJSON.object(extra.merging(item.rawFields()) { _, known in known }))
        }
        try c.encode(contentsOf: unknown)
    }
}

private struct MaybeActivity: Decodable {
    let value: Activity?

    init(from decoder: Decoder) throws {
        value = try? Activity(from: decoder)
    }
}

private extension Activity {
    func rawFields() throws -> [String: RawJSON] {
        let raw = try JSONFiles.decoder().decode(RawJSON.self, from: JSONFiles.encoder().encode(self))
        guard case let .object(fields) = raw else { throw CocoaError(.coderInvalidValue) }
        return fields
    }
}
