@testable import SathiUI
import SwiftUI
import Testing

@Suite("Main layout")
struct MainLayoutTests {
    @Test func widthBelowNineHundredIsNarrow() {
        #expect(MainLayout(width: 899).isNarrow)
        #expect(MainLayout(width: 640).isNarrow)
    }

    @Test func nineHundredAndMoreIsWide() {
        #expect(!MainLayout(width: 900).isNarrow)
        #expect(!MainLayout(width: 1440).isNarrow)
    }

    @Test func widthBelowElevenHundredUsesTheEditDrawer() {
        #expect(MainLayout(width: 1099).drawerEdit)
        #expect(MainLayout(width: 900).drawerEdit)
        #expect(MainLayout(width: 640).drawerEdit)
    }

    @Test func elevenHundredAndMoreHasNoEditDrawer() {
        #expect(!MainLayout(width: 1100).drawerEdit)
        #expect(!MainLayout(width: 1600).drawerEdit)
    }

    @Test func thresholdsComeFromTheMetrics() {
        #expect(UIMetrics.mainNarrowBelow == 900)
        #expect(UIMetrics.mainDrawerBelow == 1100)
    }

    @Test func widthsOnTheSameSideOfEveryThresholdAreEqual() {
        #expect(MainLayout(width: 700) == MainLayout(width: 899))
        #expect(MainLayout(width: 900) == MainLayout(width: 1099))
        #expect(MainLayout(width: 1100) == MainLayout(width: 2000))
    }

    @Test func widthsAcrossAThresholdAreDifferent() {
        #expect(MainLayout(width: 899) != MainLayout(width: 900))
        #expect(MainLayout(width: 1099) != MainLayout(width: 1100))
    }

    @Test func theDefaultEnvironmentLayoutIsWide() {
        let layout = EnvironmentValues().mainLayout
        #expect(!layout.isNarrow)
        #expect(!layout.drawerEdit)
    }
}
