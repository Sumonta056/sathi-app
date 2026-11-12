import Foundation

package final class FileActivityStore: ActivityStore, @unchecked Sendable {
    private let folder: URL
    private let delay: TimeInterval
    private let queue = DispatchQueue(label: "sathi.activity-store")
    private var cache: [MonthKey: MonthActivities] = [:]
    private var dirty: Set<MonthKey> = []
    private var blocked: Set<MonthKey> = []
    private var currentMonth: MonthKey?
    private var isScheduled = false

    package init(base: URL, delay: TimeInterval = Timing.saveCoalesce) {
        folder = base.appendingPathComponent(StorageKeys.activitiesFolder)
        self.delay = delay
    }

    package func month(_ key: MonthKey) -> ActivityMonth {
        queue.sync { ActivityMonth(key: key, items: contents(key).items) }
    }

    package func save(_ month: ActivityMonth) {
        queue.async { [self] in
            var file = contents(month.key)
            file.items = month.items.map(rounded)
            file.extras = file.extras.filter { entry in file.items.contains { $0.id == entry.key } }
            cache[month.key] = file
            dirty.insert(month.key)
            currentMonth = month.key
            scheduleWrite()
        }
    }

    package func savedMonths() -> [MonthKey] {
        queue.sync { Set(monthFiles()).union(dirty).sorted() }
    }

    @discardableResult
    package func backup(_ key: MonthKey) -> Bool {
        queue.sync {
            let target = backupURL(key)
            let files = FileManager.default
            guard !files.fileExists(atPath: target.path) else { return true }
            guard files.fileExists(atPath: url(key).path) else { return JSONFiles.write(contents(key), to: target) }
            return (try? files.copyItem(at: url(key), to: target)) != nil
        }
    }

    @discardableResult
    package func flush() -> Bool {
        queue.sync { writeDirty() }
    }

    private func rounded(_ item: Activity) -> Activity {
        var copy = item
        copy.start = item.start.wholeSecond
        copy.end = item.end.wholeSecond
        return copy
    }

    private func contents(_ key: MonthKey) -> MonthActivities {
        if let file = cache[key] { return file }
        let file = readMonth(key)
        cache[key] = file
        return file
    }

    private func readMonth(_ key: MonthKey) -> MonthActivities {
        let empty = MonthActivities(items: [], extras: [:], unknown: [])
        guard !blocked.contains(key) else { return empty }
        switch JSONFiles.load(MonthActivities.self, from: url(key)) {
        case .missing: return empty
        case let .value(file): return file
        case .unreadable:
            blocked.insert(key)
            return empty
        }
    }

    private func scheduleWrite() {
        guard !isScheduled else { return }
        isScheduled = true
        queue.asyncAfter(deadline: .now() + delay) { [self] in writeDirty() }
    }

    @discardableResult
    private func writeDirty() -> Bool {
        isScheduled = false
        for key in dirty where !blocked.contains(key) {
            guard let file = cache[key], JSONFiles.write(file, to: url(key)) else { continue }
            dirty.remove(key)
        }
        cache = cache.filter { $0.key == currentMonth || dirty.contains($0.key) }
        return dirty.isEmpty
    }

    private func url(_ key: MonthKey) -> URL {
        folder.appendingPathComponent(key.raw + StorageKeys.jsonExtension)
    }

    private func backupURL(_ key: MonthKey) -> URL {
        folder.appendingPathComponent(key.raw + StorageKeys.backupSuffix + StorageKeys.jsonExtension)
    }

    private func monthFiles() -> [MonthKey] {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? []
        return names.compactMap { name in
            guard name.hasSuffix(StorageKeys.jsonExtension) else { return nil }
            return MonthKey(raw: String(name.dropLast(StorageKeys.jsonExtension.count)))
        }
    }
}
