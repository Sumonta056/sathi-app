@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Setting row")
struct SettingRowTests {
    @Test func showsSectionLabelUppercased() throws {
        #expect(try SectionLabel("Daily goal").inspect().find(text: "DAILY GOAL").string() == "DAILY GOAL")
    }

    @Test func showsLabelHintAndTrailing() throws {
        let sut = try SettingRow(label: "Sound", hint: "Plays with each bubble") { Text("Pop") }.inspect()
        #expect(try sut.find(text: "Sound").string() == "Sound")
        #expect(try sut.find(text: "Plays with each bubble").string() == "Plays with each bubble")
        #expect(try sut.find(text: "Pop").string() == "Pop")
    }

    @Test func withoutHintShowsOnlyLabelAndTrailing() throws {
        let sut = try SettingRow(label: "Sound") { Text("Pop") }.inspect()
        let texts = try sut.findAll(ViewType.Text.self).map { try $0.string() }
        #expect(texts.sorted() == ["Pop", "Sound"])
    }

    @Test func settingsCardShowsItsRows() throws {
        let sut = try SettingsCard {
            SettingRow(label: "Sound", showsDivider: false) { Text("Pop") }
            SettingRow(label: "Start at login") { Text("Yes") }
        }.inspect()
        #expect(sut.findAll(SettingRow<Text>.self).count == 2)
        #expect(try sut.find(text: "Sound").string() == "Sound")
        #expect(try sut.find(text: "Start at login").string() == "Start at login")
    }
}
