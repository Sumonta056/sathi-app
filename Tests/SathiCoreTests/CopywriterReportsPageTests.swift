import Foundation
@testable import SathiCore
import Testing

@Suite("Copywriter reports page")
struct CopywriterReportsPageTests {
    @Test func waterTotalIsInGlassesAndTheOthersAreLengths() {
        #expect(Copywriter.reportsAmount(.water, 49) == "49 glasses")
        #expect(Copywriter.reportsAmount(.reading, 140) == "2h 20m")
        #expect(Copywriter.reportsAmount(.gym, 95) == "1h 35m")
        #expect(Copywriter.reportsAmount(.meditation, 0) == "0m")
    }

    @Test func categoryTitleNamesTheComparedRange() {
        #expect(Copywriter.reportsCategoryTitle(.week) == "Time by category vs last week")
        #expect(Copywriter.reportsCategoryTitle(.day) == "Time by category vs yesterday")
        #expect(Copywriter.reportsCategoryTitle(.month) == "Time by category vs last month")
    }

    @Test func deltaIsTheSignedAmountWithoutTheComparison() {
        let format: (Double) -> String = { "\(Int($0))m" }
        #expect(Copywriter.rangeDelta(.up(20), format: format) == "+20m")
        #expect(Copywriter.rangeDelta(.down(5), format: format) == "\u{2212}5m")
        #expect(Copywriter.rangeDelta(.same, format: format) == "")
        #expect(Copywriter.rangeDelta(.none, format: format) == "")
    }

    @Test func fixedTexts() {
        #expect(Copywriter.reportsExport == "Export CSV")
        #expect(Copywriter.reportsExportFailed == "Could not save the file.")
        #expect(Copywriter.reportsNoActivities == "No activities in this range.")
    }
}
