import SathiCore
import Testing

@Suite("Sidebar copy")
struct CopywriterSidebarTests {
    @Test func settingsPagesHaveTheirSidebarTitlesInOrder() {
        let titles = SettingsPage.all.map(Copywriter.sidebarSettingsTitle)
        #expect(titles == [
            "General",
            "Fota · water",
            "Boi · reading",
            "Shanti · calm",
            "Shokti · gym",
            "Quick reminders",
            "Activity tracker",
            "Time blocks",
            "Sound"
        ])
    }

    @Test func footerShowsVersionAndMaker() {
        #expect(Copywriter.sidebarFooter(version: "3.0.0") == "Sathi 3.0.0 · by Sumonta")
        #expect(Copywriter.sidebarFooter(version: nil) == "Sathi · by Sumonta")
    }

    @Test func railVersionFallsBackToTheAppName() {
        #expect(Copywriter.sidebarVersion("3.0.0") == "3.0.0")
        #expect(Copywriter.sidebarVersion(nil) == "Sathi")
    }

    @Test func labelsAreStable() {
        #expect(Copywriter.sidebarOpenLabel == "Open sidebar")
        #expect(Copywriter.sidebarCloseLabel == "Close sidebar")
        #expect(Copywriter.sidebarSettingsHeading == "SETTINGS")
    }

    @Test func sidebarKeyIsNotAPrefsKey() {
        #expect(StorageKeys.sidebarOpen == "sathi.ui.sidebarOpen")
    }
}
