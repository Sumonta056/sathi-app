import Foundation

extension Engine {
    package func exportActivityMonth(_ key: MonthKey, to folder: URL) -> [URL] {
        let month = activityStore.month(key)
        let files: [(ExportFormat, Data)] = [
            (.json, ActivityMonthExporter.json(month, exportedAt: clock.now.wholeSecond)),
            (.csv, Data(ActivityMonthExporter.csv(month, timeZone: calendar.timeZone).utf8))
        ]
        guard (try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)) != nil else { return [] }
        return files.compactMap { format, data in
            let url = Self.freeURL(in: folder, name: ActivityMonthExporter.fileName(key, format: format))
            return (try? data.write(to: url, options: .withoutOverwriting)) == nil ? nil : url
        }
    }

    static func freeURL(in folder: URL, name: String) -> URL {
        let first = folder.appendingPathComponent(name)
        guard FileManager.default.fileExists(atPath: first.path) else { return first }
        let base = first.deletingPathExtension().lastPathComponent
        let ext = first.pathExtension
        var n = Limits.firstCopyNumber
        while true {
            let url = folder.appendingPathComponent("\(base) (\(n))").appendingPathExtension(ext)
            if !FileManager.default.fileExists(atPath: url.path) { return url }
            n += 1
        }
    }
}
