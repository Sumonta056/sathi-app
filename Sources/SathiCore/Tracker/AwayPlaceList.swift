import Foundation

package enum AwayPlaceList {
    package static func name(_ raw: String) -> String? {
        let cut = String(raw.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Limits.awayPlaceNameMax))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cut.isEmpty, !AwayPlace.allCases.contains(where: { same(Copywriter.trackerAwayPlace($0), cut) }) else { return nil }
        return cut
    }

    package static func clean(_ names: [String]) -> [String] {
        var list: [String] = []
        for raw in names {
            guard list.count < Limits.awayPlaceMax else { break }
            guard let valid = name(raw), !list.contains(where: { same($0, valid) }) else { continue }
            list.append(valid)
        }
        return list
    }

    package static func adding(_ raw: String, to names: [String]) -> [String]? {
        guard names.count < Limits.awayPlaceMax, let valid = name(raw), !names.contains(where: { same($0, valid) }) else { return nil }
        return names + [valid]
    }

    private static func same(_ a: String, _ b: String) -> Bool {
        a.caseInsensitiveCompare(b) == .orderedSame
    }
}
