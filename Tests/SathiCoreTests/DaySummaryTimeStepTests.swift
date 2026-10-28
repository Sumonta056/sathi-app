import Foundation
import SathiCore
import Testing

@Suite("Day summary time step")
struct DaySummaryTimeStepTests {
    private func general(_ minutes: Int) throws -> GeneralPrefs {
        let json = #"{"name":"Asha","daySummaryOn":false,"daySummaryMinutes":\#(minutes)}"#
        return try JSONDecoder().decode(GeneralPrefs.self, from: Data(json.utf8))
    }

    @Test(arguments: [1, 7, 1321, 1339, 1425 + 1])
    func aTimeOffTheStepLoadsTheDefault(_ minutes: Int) throws {
        let g = try general(minutes)
        #expect(g.daySummaryMinutes == Limits.daySummaryMinutes)
        #expect(!g.daySummaryOn)
        #expect(g.name == "Asha")
    }

    @Test(arguments: [0, 15, 30, 1305, 1425])
    func aTimeOnTheStepLoads(_ minutes: Int) throws {
        #expect(try general(minutes).daySummaryMinutes == minutes)
    }
}
