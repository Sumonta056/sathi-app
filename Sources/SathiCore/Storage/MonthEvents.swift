import Foundation

struct MonthEvents: Codable {
    var events: [HistoryEvent]
    var extras: [[String: RawJSON]]
    var unknown: [RawJSON]

    init(events: [HistoryEvent], extras: [[String: RawJSON]], unknown: [RawJSON]) {
        self.events = events
        self.extras = extras
        self.unknown = unknown
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        let raw = try c.decode([RawJSON].self)
        let parsed = try c.decode([MaybeEvent].self)
        events = []
        extras = []
        unknown = []
        for (value, maybe) in zip(raw, parsed) {
            if let event = maybe.value, case let .object(fields) = value {
                let known = try event.rawFields()
                events.append(event)
                extras.append(fields.filter { known[$0.key] == nil })
            } else {
                unknown.append(value)
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.unkeyedContainer()
        for (index, event) in events.enumerated() {
            let extra = index < extras.count ? extras[index] : [:]
            try c.encode(RawJSON.object(extra.merging(event.rawFields()) { _, known in known }))
        }
        try c.encode(contentsOf: unknown)
    }
}

private struct MaybeEvent: Decodable {
    let value: HistoryEvent?

    init(from decoder: Decoder) throws {
        value = try? HistoryEvent(from: decoder)
    }
}

private extension HistoryEvent {
    func rawFields() throws -> [String: RawJSON] {
        let raw = try JSONFiles.decoder().decode(RawJSON.self, from: JSONFiles.encoder().encode(self))
        guard case let .object(fields) = raw else { throw CocoaError(.coderInvalidValue) }
        return fields
    }
}
