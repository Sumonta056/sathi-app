import Foundation

struct LegacyV1: Decodable {
    struct Drink: Decodable {
        var date: Date
        var glasses: Double
    }

    struct Read: Decodable {
        var date: Date
        var minutes: Int
    }

    var prefs: LegacyV1Prefs
    var drinks: [Drink]
    var reads: [Read]
    var bottleLevel: Double
    var lastWaterDone: Date?
    var streakReset: [String: Date]

    private enum CodingKeys: String, CodingKey {
        case prefs, drinks, reads, bottleLevel, lastWaterDone, streakReset
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        prefs = try c.value(.prefs, or: LegacyV1Prefs(from: Prefs()))
        drinks = try c.value(.drinks, or: [])
        reads = try c.value(.reads, or: [])
        bottleLevel = try c.value(.bottleLevel, or: LiveState().bottleLevel)
        lastWaterDone = try c.decodeIfPresent(Date.self, forKey: .lastWaterDone)
        streakReset = try c.value(.streakReset, or: [:])
    }

    var live: LiveState {
        var l = LiveState()
        l.bottleLevel = bottleLevel
        l.lastWaterDone = lastWaterDone?.wholeSecond
        l.streakReset = streakReset.mapValues(\.wholeSecond)
        return l
    }

    var events: [HistoryEvent] {
        drinks.map { .done(.water, $0.glasses, at: $0.date) } + reads.map { .done(.reading, Double($0.minutes), at: $0.date) }
    }
}
