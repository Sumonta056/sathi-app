import AppKit
@testable import SathiCore
@testable import SathiUI
import SwiftUI

@MainActor
enum BackFit {
    static let titles = [
        "Personal Work · Google", "Cefalo Meetings · Google", "someone.long.name@example.com",
        "Family Birthdays · iCloud", "Team Standups · Outlook", "Client Projects · Google",
        "Holidays in Bangladesh", "Reading Club · iCloud", "Gym and Health · Google",
        "Sprint Planning · Outlook", "Side Project Ideas · iCloud", "Doctor Visits · Google",
        "Travel Plans · iCloud", "Company Events · Outlook", "Learning Swift · Google"
    ]

    static let colors: [UInt32] = (0 ..< 15).map { i in
        let r = UInt32(10 + i * 16)
        let g = UInt32(250 - i * 15)
        let b = UInt32(3 + i * 7)
        return (r << 16) | (g << 8) | b
    }

    static let calendars: [CalendarChoice] = titles.indices.map {
        CalendarChoice(id: "c\($0 + 1)", title: titles[$0], account: "Google", colorHex: colors[$0])
    }

    static let places = [
        "Doctor appointment visit", "Kids school pickup run", "Grocery shopping trip",
        "Lunch with the team now", "Coffee break downstairs", "Bank and post office",
        "Evening walk in the park", "Prayer at the mosque now"
    ]

    static let categories = colored([
        "Coding Hobby", "Client Meeting", "Cefalo Meetings", "Code Review", "Learning", "Coding Client",
        "Reading", "Browsing", "Break", "Gym", "Organizing", "Meditation", "Office Work", "Planning",
        "Email", "Admin"
    ])

    static let longCategories = colored([
        "Coding Hobby", "Client Meeting", "Cefalo Meetings", "Code Review", "Planning Work",
        "Reading Articles", "Writing Docs", "Learning Swift", "Email and Chat", "Design Mockups",
        "Interview Prep", "Support Tickets", "Team Standups", "Research Notes", "Client Proposals",
        "Admin and Billing"
    ])

    private static func colored(_ names: [String]) -> [ActivityCategory] {
        names.enumerated().map { ActivityCategory(name: $1, colorHex: ActivityCategory.palette[$0 % ActivityCategory.palette.count]) }
    }

    static func state(picked: String? = nil) -> TrackerPromptState {
        Prompt.state(.welcomeBack) { s in
            s.lastActivity = ActivityDraft(text: "Code review", category: "Code Review")
            s.stoppedByAway = "Code review"
            s.away = AwaySpan(start: Prompt.now.addingTimeInterval(-2100), end: Prompt.now, cause: .locked)
            s.places = places
            s.categories = categories
            s.calendars = calendars
            s.calendarAccess = .allowed
            s.draft.calendarID = picked
        }
    }

    static let rowWidth = UIMetrics.activityPromptWidth - UIMetrics.promptPaneWidth - UIMetrics.promptBodyPadding.leading
        - UIMetrics.promptBodyPadding.trailing - UIMetrics.promptRowLabelWidth

    static func host(_ view: some View, size: CGSize? = nil) -> NSHostingView<some View> {
        let host = NSHostingView(rootView: view.environment(\.colorScheme, .dark))
        host.frame = CGRect(origin: .zero, size: size ?? host.fittingSize)
        for _ in 0 ..< 3 {
            host.layoutSubtreeIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
        return host
    }

    static func hasScroll(_ v: NSView) -> Bool {
        scrollView(v) != nil
    }

    static func scrollView(_ v: NSView) -> NSScrollView? {
        if let s = v as? NSScrollView { return s }
        return v.subviews.lazy.compactMap { scrollView($0) }.first
    }

    static func scrollBarHidden(_ s: NSScrollView) -> Bool {
        !s.hasVerticalScroller
    }

    static func drawnCalendars(_ host: NSView) -> Set<String> {
        guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { return [] }
        host.cacheDisplay(in: host.bounds, to: rep)
        guard let rgb = rep.converting(to: .sRGB, renderingIntent: .default), rgb.bitsPerSample == 8,
              let data = rgb.bitmapData else { return [] }
        let targets = colors.map { (Int($0 >> 16), Int(($0 >> 8) & 255), Int($0 & 255)) }
        var found = Set<String>()
        for y in 0 ..< rgb.pixelsHigh {
            let row = data + y * rgb.bytesPerRow
            for x in 0 ..< rgb.pixelsWide {
                let p = row + x * rgb.samplesPerPixel
                let r = Int(p[0])
                let g = Int(p[1])
                let b = Int(p[2])
                for (i, t) in targets.enumerated() where abs(r - t.0) <= 2 && abs(g - t.1) <= 2 && abs(b - t.2) <= 2 {
                    found.insert("c\(i + 1)")
                }
            }
        }
        return found
    }
}
