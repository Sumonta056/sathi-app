import SathiCore

enum EndOfDayAnimation {
    static func reveal(count: Int, revealed: Bool, reduceMotion: Bool) -> RibbonReveal? {
        guard !reduceMotion else { return nil }
        return RibbonReveal(revealed: revealed, grow: UIMetrics.trackerEndOfDayGrow, stagger: stagger(count: count))
    }

    static func stagger(count: Int) -> Double {
        guard count > 1 else { return 0 }
        let room = Timing.endOfDayAnimation - UIMetrics.trackerEndOfDayGrow
        return min(UIMetrics.trackerEndOfDayStagger, max(0, room) / Double(count - 1))
    }

    static func totalDuration(count: Int) -> Double {
        UIMetrics.trackerEndOfDayGrow + stagger(count: count) * Double(max(0, count - 1))
    }
}
