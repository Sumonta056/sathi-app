import Foundation

package enum ActivityLength: Codable, Hashable, Sendable {
    case open
    case minutes(Int)

    private static let openRaw = "open"

    package static var choices: [ActivityLength] {
        Limits.activityLengths.map(ActivityLength.minutes) + [.open]
    }

    package var minutes: Int? {
        switch self {
        case .open: return nil
        case let .minutes(n): return n
        }
    }

    package var interval: TimeInterval? {
        minutes.map { TimeInterval($0) * Timing.minute }
    }

    package init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let n = try? c.decode(Int.self), n > 0 {
            self = .minutes(n)
        } else if (try? c.decode(String.self)) == Self.openRaw {
            self = .open
        } else {
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Unknown activity length")
        }
    }

    package func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .open: try c.encode(Self.openRaw)
        case let .minutes(n): try c.encode(n)
        }
    }
}
