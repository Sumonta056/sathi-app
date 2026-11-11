import Foundation

enum MenuFooter {
    static var versionText: String {
        guard let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else { return "Sathi" }
        return "Sathi \(v)"
    }
}
