import AppKit
import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing

enum ShotFolder {
    static let path = ProcessInfo.processInfo.environment["SATHI_SHOTS"]
}

@MainActor
enum Shots {
    nonisolated static let today = day(2026, 3, 26, 10, 30)

    static func sampleEvents() -> [HistoryEvent] {
        let water: [Double] = [8, 8, 8, 8, 8, 8, 8, 8, 8, 7, 8, 8, 5, 8, 8, 8, 6, 8, 8, 3, 8, 8, 8, 7, 8]
        let reading: [Double] = [15, 20, 15, 0, 15, 30, 15, 15, 10, 15, 15, 20, 15, 0, 15, 15, 20, 15, 5, 15, 15, 0, 15, 15, 15]
        let calm: [Double] = [10, 10, 5, 10, 10, 0, 10, 10, 10, 5, 10, 10, 0, 10, 10, 10, 10, 5, 10, 10, 0, 10, 10, 10, 10]
        let gym: [Int] = [4, 4, 3, 4, 4, 2, 4, 4, 4, 4, 1, 4, 4, 4, 3, 4, 4, 4, 0, 4, 4, 4, 3, 4, 4]
        var events: [HistoryEvent] = []
        for back in 1 ... water.count {
            let date = Calendar.current.date(byAdding: .day, value: -back, to: day(2026, 3, 26, 12))!
            events.append(.done(.water, water[back - 1], at: date))
            if reading[back - 1] > 0 { events.append(.done(.reading, reading[back - 1], at: date)) }
            if calm[back - 1] > 0 { events.append(.done(.meditation, calm[back - 1], at: date)) }
            for _ in 0 ..< gym[back - 1] {
                events.append(.done(.gym, 1, at: date))
            }
        }
        events.append(.done(.water, 4, at: day(2026, 3, 26, 9, 40)))
        events.append(.done(.meditation, 10, at: day(2026, 3, 26, 8, 10)))
        events.append(.done(.gym, 1, at: day(2026, 3, 26, 10, 5)))
        return events
    }

    static func harness(
        at start: Date = today,
        others: Bool = true,
        configure: (inout Persisted) -> Void = { _ in }
    ) -> EngineHarness {
        EngineHarness(at: start) {
            $0.prefs.water.enabled = others
            $0.prefs.general.name = "Alex"
            $0.prefs.meditation.enabled = others
            $0.prefs.gym.enabled = others
            $0.events = sampleEvents()
            configure(&$0)
        }
    }

    static func save(_ view: some View, _ name: String, _ h: EngineHarness) throws {
        let host = NSHostingView(rootView: view.environmentObject(h.engine).environment(\.colorScheme, .dark))
        host.frame = CGRect(origin: .zero, size: host.fittingSize)
        let window = NSWindow(contentRect: host.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        host.display()
        let rep = try #require(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        host.cacheDisplay(in: host.bounds, to: rep)
        let png = try #require(rep.representation(using: .png, properties: [:]))
        let url = try URL(fileURLWithPath: #require(ShotFolder.path)).appendingPathComponent("\(name).png")
        try png.write(to: url)
    }
}
