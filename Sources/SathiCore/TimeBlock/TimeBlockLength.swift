import Foundation

package enum TimeBlockLength: Codable, Equatable, Hashable, Sendable {
    case open
    case minutes(Int)

    private static let openRaw = "open"

    package static var choices: [TimeBlockLength] {
        [.open] + Limits.blockLengths.map(TimeBlockLength.minutes)
    }

    package var minutes: Int? {
        switch self {
        case .open: return nil
        case let .minutes(n): return n
        }
    }

    package init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let n = try? c.decode(Int.self), n > 0 {
            self = .minutes(n)
        } else if try c.decode(String.self) == Self.openRaw {
            self = .open
        } else {
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Unknown time block length")
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

package enum TimeBlockDisplay: String, Codable, CaseIterable, Sendable {
    case menuBar
    case widget
}

package enum TimeBlockText {
    package static func clean(_ raw: String) -> String {
        let joined = String(raw.map { $0.isNewline ? " " : $0 })
        let trimmed = joined.trimmingCharacters(in: .whitespacesAndNewlines)
        let cut = String(trimmed.prefix(Limits.blockTitleMax)).trimmingCharacters(in: .whitespaces)
        return cut.isEmpty ? Copywriter.blockDefaultTitle : cut
    }
}
