import Foundation

enum ReadingLink {
    static let schemes: Set<String> = ["http", "https", "file"]

    static func parse(_ text: String) -> Result<URL, ReadingAddResult> {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let full = hasScheme(trimmed) ? trimmed : "https://" + trimmed
        guard let url = URL(string: full) else { return .failure(.missingHost) }
        if let reason = problem(with: url) { return .failure(reason) }
        return .success(url)
    }

    static func problem(with url: URL) -> ReadingAddResult? {
        guard let scheme = url.scheme?.lowercased() else { return .missingHost }
        guard schemes.contains(scheme) else { return .unsupportedScheme }
        guard url.absoluteString.count <= Limits.readingURLMax else { return .tooLong }
        if scheme == "file" { return url.path.count > 1 && url.path.hasPrefix("/") ? nil : .missingHost }
        return url.host?.isEmpty ?? true ? .missingHost : nil
    }

    static func cleanTitle(_ title: String) -> String {
        String(title.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Limits.readingTitleMax))
    }

    private static func hasScheme(_ text: String) -> Bool {
        text.firstMatch(of: #/^[A-Za-z][A-Za-z0-9+.-]*:(?![0-9])/#) != nil
    }
}
