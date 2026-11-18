import SathiCore
import SwiftUI

struct CalendarHoverTarget: Equatable {
    let day: DayKey
    let laid: CalendarLaidBlock
    let among: [CalendarLaidBlock]
    let rect: CGRect
    let radius: CGFloat
    let prefersLeft: Bool

    var id: String { laid.id }

    func row(_ id: String) -> CalendarBlock? {
        let all = ([laid] + among).flatMap { [$0] + $0.hidden }
        return all.first { $0.id == id }?.block
    }
}

@MainActor
final class CalendarHoverHost: ObservableObject {
    static let space = "calendar.hover"

    @Published private(set) var shown: CalendarHoverTarget?
    @Published var todoEdit: CalendarHoverTarget?
    private var inside: [CalendarHoverTarget] = []
    private var onCard = false
    private var task: Task<Void, Never>?
    private let wait: (TimeInterval) async -> Void

    init(wait: @escaping (TimeInterval) async -> Void = CalendarHoverHost.sleep) {
        self.wait = wait
    }

    nonisolated static func sleep(_ delay: TimeInterval) async {
        try? await Task.sleep(for: .seconds(delay))
    }

    func block(_ target: CalendarHoverTarget, inside isInside: Bool) {
        inside.removeAll { $0.id == target.id }
        if isInside { inside.append(target) }
        settle()
    }

    func card(_ isInside: Bool) {
        onCard = isInside
        settle()
    }

    func close() {
        task?.cancel()
        task = nil
        inside = []
        onCard = false
        shown = nil
    }

    func keep(ids: Set<String>) {
        guard let id = shown?.id ?? inside.last?.id, !ids.contains(id) else { return }
        close()
    }

    func settled() async {
        await task?.value
    }

    private func settle() {
        task?.cancel()
        task = nil
        if onCard, shown != nil { return }
        guard let next = inside.last else {
            if shown != nil { schedule(Timing.calendarHoverCloseDelay, nil) }
            return
        }
        if next.id != shown?.id { schedule(Timing.calendarHoverOpenDelay, next) }
    }

    private func schedule(_ delay: TimeInterval, _ next: CalendarHoverTarget?) {
        task = Task { [weak self, wait] in
            await wait(delay)
            guard !Task.isCancelled, let self else { return }
            shown = next
        }
    }
}

@MainActor
final class CalendarHoverBox {
    private(set) lazy var host = CalendarHoverHost()
}

enum CalendarHoverPlacement {
    static func prefersLeft(weekday: Int) -> Bool {
        Limits.calendarHoverLeftWeekdays.contains(weekday)
    }

    static func prefersLeft(day: DayKey, calendar: Calendar) -> Bool {
        prefersLeft(weekday: calendar.component(.weekday, from: day.start(in: calendar)))
    }

    static func x(block: CGRect, card: CGFloat, width: CGFloat, prefersLeft: Bool) -> CGFloat {
        let right = block.maxX + UIMetrics.calendarHoverGap
        let left = block.minX - UIMetrics.calendarHoverGap - card
        let fitsRight = right + card <= width
        let fitsLeft = left >= 0
        let x = prefersLeft ? (fitsLeft || !fitsRight ? left : right) : (fitsRight || !fitsLeft ? right : left)
        return min(max(0, x), max(0, width - card))
    }

    static func y(block: CGRect, height: CGFloat) -> CGFloat {
        min(max(0, block.minY), max(0, height - UIMetrics.calendarHoverHeightGuess))
    }
}
