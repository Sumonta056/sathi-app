import Foundation

package struct ActivityID: Hashable, Codable, Sendable {
    package let raw: UUID

    package init(_ raw: UUID = UUID()) {
        self.raw = raw
    }

    package init(from decoder: Decoder) throws {
        raw = try decoder.singleValueContainer().decode(UUID.self)
    }

    package func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(raw)
    }
}
