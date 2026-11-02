import Foundation
import SathiCore
import Testing

@Suite("Time block prefs decoding")
struct TimeBlockPrefsDecodingTests {
    private func prefs(_ json: String) throws -> Prefs {
        try JSONDecoder().decode(Prefs.self, from: Data(json.utf8))
    }

    @Test func oldPrefsWithoutTheKeyLoadDefaults() throws {
        let p = try prefs(#"{"water":{"intervalMinutes":45},"general":{"name":"Asha"}}"#)
        #expect(p.timeBlock == TimeBlockPrefs())
        #expect(p.timeBlock.defaultCalendarID == nil)
        #expect(p.timeBlock.lastLength == .minutes(30))
        #expect(p.timeBlock.display == .menuBar)
        #expect(p.timeBlock.playsSound)
        #expect(p.water.intervalMinutes == 45)
    }

    @Test func aBadKeyKeepsOtherSettings() throws {
        let p = try prefs(#"{"timeBlock":"oops","water":{"intervalMinutes":45}}"#)
        #expect(p.timeBlock == TimeBlockPrefs())
        #expect(p.water.intervalMinutes == 45)
    }

    @Test func unknownDisplayLoadsDefault() throws {
        let p = try prefs(#"{"timeBlock":{"display":"sideways","playsSound":false,"defaultCalendarID":"work"}}"#)
        #expect(p.timeBlock.display == .menuBar)
        #expect(!p.timeBlock.playsSound)
        #expect(p.timeBlock.defaultCalendarID == "work")
    }

    @Test func savedValuesLoad() throws {
        let p = try prefs(#"{"timeBlock":{"display":"widget","playsSound":false}}"#)
        #expect(p.timeBlock.display == .widget)
        #expect(!p.timeBlock.playsSound)
    }

    @Test func lastLengthRoundTrips() throws {
        for length in [TimeBlockLength.open, .minutes(45)] {
            var p = Prefs()
            p.timeBlock.lastLength = length
            let back = try JSONDecoder().decode(Prefs.self, from: JSONEncoder().encode(p))
            #expect(back.timeBlock.lastLength == length)
        }
    }

    @Test func unknownLengthLoadsDefault() throws {
        var p = Prefs()
        p.timeBlock.lastLength = .minutes(45)
        let data = try JSONEncoder().encode(p)
        var root = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        var block = try #require(root["timeBlock"] as? [String: Any])
        block["lastLength"] = "weird"
        root["timeBlock"] = block
        let bad = try JSONSerialization.data(withJSONObject: root)
        let back = try JSONDecoder().decode(Prefs.self, from: bad)
        #expect(back.timeBlock.lastLength == .minutes(30))
    }
}
