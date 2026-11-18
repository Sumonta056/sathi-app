import Foundation

package enum TodoTitlePart: Equatable, Sendable {
    case text(String)
    case link(label: String, url: URL)

    package static func parts(of title: String) -> [TodoTitlePart] {
        guard !title.isEmpty else { return [] }
        let all = NSRange(title.startIndex..., in: title)
        let found = detector?.matches(in: title, range: all) ?? []
        var out: [TodoTitlePart] = []
        var cursor = title.startIndex
        for match in found {
            guard let range = Range(match.range, in: title), let url = webURL(match, written: title[range]) else { continue }
            if cursor < range.lowerBound { out.append(.text(String(title[cursor ..< range.lowerBound]))) }
            out.append(.link(label: label(url), url: url))
            cursor = range.upperBound
        }
        if cursor < title.endIndex { out.append(.text(String(title[cursor...]))) }
        return out
    }

    package static func isWeb(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }

    private static func webURL(_ match: NSTextCheckingResult, written: Substring) -> URL? {
        guard let found = match.url, isWeb(found) else { return nil }
        guard written.range(of: "://") == nil else { return found }
        guard written.lowercased().hasPrefix("www.") else { return nil }
        var parts = URLComponents(url: found, resolvingAgainstBaseURL: false)
        parts?.scheme = "https"
        return parts?.url
    }

    private static let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

    private static func label(_ url: URL) -> String {
        var host = url.host ?? ""
        if host.lowercased().hasPrefix("www.") { host.removeFirst(4) }
        var path = url.path
        while path.hasSuffix("/") {
            path.removeLast()
        }
        let full = host + path
        guard full.count > Limits.todoLinkLabelMax else { return full }
        return String(full.prefix(Limits.todoLinkLabelMax - 1)) + "…"
    }
}
