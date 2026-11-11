import Foundation

extension Engine {
    package func activityDays(in range: StatsRange) -> [ActivityDay] {
        activityDays(overlapping: range.interval)
    }

    package func activityRange(_ range: StatsRange) -> ActivityRangeStats {
        let compare = range.comparable(now: clock.now, calendar: calendar)
        return ActivityRangeStats(activityDays(in: range), compare: activityDays(overlapping: compare))
    }

    package func exportActivities(_ range: StatsRange, to folder: URL) -> URL? {
        let items = monthsTouched(by: range.interval).flatMap { activityStore.month($0).items }
            .filter { range.holds($0.start) }
        guard !items.isEmpty else { return nil }
        let csv = ActivityRangeExporter.csv(items, timeZone: calendar.timeZone)
        return writeExport(Data(csv.utf8), name: ActivityRangeExporter.fileName(range, calendar: calendar), to: folder)
    }

    package func exportHistory(_ range: StatsRange, to folder: URL) -> URL? {
        let events = history.events(from: range.interval.start, to: range.interval.end)
        guard !events.isEmpty else { return nil }
        let csv = CSVExporter.csv(events, timeZone: calendar.timeZone)
        return writeExport(Data(csv.utf8), name: HistoryRangeExporter.fileName(range, calendar: calendar), to: folder)
    }

    private func activityDays(overlapping interval: DateInterval) -> [ActivityDay] {
        var keys: [DayKey] = []
        var start = interval.start
        while start < interval.end {
            keys.append(DayKey(start, calendar: calendar))
            start = calendar.nextDay(after: start)
        }
        let active = monthsTouched(by: interval).reduce(into: Set<DayKey>()) { $0.formUnion(daysWithActivities(in: $1)) }
        return keys.filter(active.contains).map { key in
            var day = activityDay(key)
            let end = max(day.hours.start, min(day.hours.end, interval.end))
            day.hours = DateInterval(start: day.hours.start, end: end)
            return day
        }
    }

    private func monthsTouched(by interval: DateInterval) -> [MonthKey] {
        var months: [MonthKey] = []
        var month = MonthKey(interval.start, calendar: calendar)
        let last = MonthKey(interval.end.addingTimeInterval(-Timing.second), calendar: calendar)
        while month <= last {
            months.append(month)
            month = month.next
        }
        return months
    }

    private func writeExport(_ data: Data, name: String, to folder: URL) -> URL? {
        guard (try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)) != nil else { return nil }
        let url = Self.freeURL(in: folder, name: name)
        return (try? data.write(to: url, options: .withoutOverwriting)) == nil ? nil : url
    }
}
