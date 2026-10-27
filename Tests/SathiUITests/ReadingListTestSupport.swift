import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import ViewInspector

enum Books {
    static func unread(_ title: String, host: String) -> ReadingItem {
        ReadingItem(title: title, url: URL(string: "https://\(host)/post")!, addedOn: DayKey(raw: "2026-03-01")!)
    }

    static func read(_ title: String, host: String, on raw: String) -> ReadingItem {
        ReadingItem(title: title, url: URL(string: "https://\(host)/post")!, addedOn: DayKey(raw: "2026-02-01")!, doneOn: DayKey(raw: raw)!)
    }

    static let alpha = unread("Alpha", host: "alpha.com")
    static let beta = unread("Beta", host: "beta.com")
    static let gamma = unread("Gamma", host: "gamma.com")
    static let old = read("Old", host: "old.com", on: "2026-03-03")
    static let older = read("Older", host: "older.com", on: "2026-03-01")

    @MainActor
    static func harness(_ list: [ReadingItem]) -> EngineHarness {
        EngineHarness { $0.prefs.reading.list = list }
    }

    @MainActor
    static func titles(_ h: EngineHarness) -> [String] {
        h.engine.data.prefs.reading.list.map(\.title)
    }

    @MainActor
    static func card(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(ReadingListCard(paste: { nil }), h).inspect()
    }

    @MainActor
    static func texts(_ sut: InspectableView<some BaseViewType>) -> [String] {
        sut.findAll(ViewType.Text.self).compactMap { try? $0.string() }
    }

    @MainActor
    static func lacksButton(_ sut: InspectableView<some BaseViewType>, label: String) -> Bool {
        (try? Find.button(sut, label: label)) == nil
    }
}

@MainActor
final class AddRowState {
    var link: String
    var title: String
    var problem: ReadingAddResult?
    var clipboard: String?

    init(link: String = "", title: String = "", problem: ReadingAddResult? = nil, clipboard: String? = nil) {
        self.link = link
        self.title = title
        self.problem = problem
        self.clipboard = clipboard
    }

    func row() -> ReadingAddRow {
        ReadingAddRow(
            link: Binding(get: { self.link }, set: { self.link = $0 }),
            title: Binding(get: { self.title }, set: { self.title = $0 }),
            problem: Binding(get: { self.problem }, set: { self.problem = $0 }),
            paste: { self.clipboard }
        )
    }

    func inspect(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(row(), h).inspect()
    }

    static func field(_ sut: InspectableView<some BaseViewType>, _ placeholder: String) throws -> InspectableView<ViewType.TextField> {
        try sut.find(text: placeholder).find(ViewType.TextField.self, relation: .parent)
    }
}
