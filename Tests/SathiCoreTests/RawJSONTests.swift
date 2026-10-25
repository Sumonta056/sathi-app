import Foundation
@testable import SathiCore
import Testing

@Suite("RawJSON")
struct RawJSONTests {
    private let nested = #"{"a":null,"b":true,"c":false,"i":42,"f":2.5,"s":"st","l":[1,-7,0.25,"x",null,{"d":[false]}],"o":{"k":{"m":[]},"e":{}}}"#

    private func decode(_ text: String) throws -> RawJSON {
        try JSONDecoder().decode(RawJSON.self, from: Data(text.utf8))
    }

    @Test func aNestedValueEncodesToTheSameParsedJSON() throws {
        let value = try decode(nested)
        let encoded = try JSONEncoder().encode(value)
        #expect(try JSONDecoder().decode(RawJSON.self, from: encoded) == value)
    }

    @Test func eachKindOfValueDecodesToItsCase() throws {
        let value = try decode(#"{"n":null,"b":true,"i":42,"f":2.5,"s":"x","a":[1],"o":{}}"#)
        let expected = RawJSON.object([
            "n": .null,
            "b": .bool(true),
            "i": .number(42),
            "f": .number(2.5),
            "s": .string("x"),
            "a": .array([.number(1)]),
            "o": .object([:])
        ])
        #expect(value == expected)
    }

    @Test func anIntegerStaysAnIntegerAndABoolStaysABool() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let encoded = try encoder.encode(decode(#"{"b":true,"i":42,"z":0}"#))
        #expect(String(bytes: encoded, encoding: .utf8) == #"{"b":true,"i":42,"z":0}"#)
    }

    @Test(arguments: ["null", "true", "17", "-0.5", #""text""#, "[]", "{}"])
    func aTopLevelValueRoundTrips(_ text: String) throws {
        let value = try decode(text)
        let encoded = try JSONEncoder().encode(value)
        #expect(try JSONDecoder().decode(RawJSON.self, from: encoded) == value)
    }
}
