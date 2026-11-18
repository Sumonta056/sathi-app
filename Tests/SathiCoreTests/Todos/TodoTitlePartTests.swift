import Foundation
import SathiCore
import SathiTestSupport
import Testing

private func url(_ s: String) -> URL { URL(string: s)! }

@Suite("TodoTitlePart")
struct TodoTitlePartTests {
    static let cases: [(String, [TodoTitlePart])] = [
        ("Buy milk", [.text("Buy milk")]),
        ("", []),
        (
            "https://www.facebook.com/share/r/1Cfu9BXFAM/?mibextid=wwXIfr",
            [.link(label: "facebook.com/share/r/1Cfu9BXFAM", url: url("https://www.facebook.com/share/r/1Cfu9BXFAM/?mibextid=wwXIfr"))]
        ),
        (
            "https://console.typesafe.ai/homen : Try jev",
            [.link(label: "console.typesafe.ai/homen", url: url("https://console.typesafe.ai/homen")), .text(" : Try jev")]
        ),
        (
            "Read https://a.com and https://b.com/x today",
            [
                .text("Read "),
                .link(label: "a.com", url: url("https://a.com")),
                .text(" and "),
                .link(label: "b.com/x", url: url("https://b.com/x")),
                .text(" today")
            ]
        ),
        ("https://example.com/", [.link(label: "example.com", url: url("https://example.com/"))]),
        ("http://example.com/a#top", [.link(label: "example.com/a", url: url("http://example.com/a#top"))]),
        (
            "see www.example.com/x now",
            [.text("see "), .link(label: "example.com/x", url: url("https://www.example.com/x")), .text(" now")]
        )
    ]

    @Test(arguments: cases)
    func splitsTheTitle(_ title: String, _ expected: [TodoTitlePart]) {
        #expect(TodoTitlePart.parts(of: title) == expected)
    }

    @Test(arguments: ["mailto:a@b.com", "file:///tmp/x", "slack://open", "Write to mailto:a@b.com today"])
    func otherSchemesStayText(_ title: String) {
        #expect(TodoTitlePart.parts(of: title) == [.text(title)])
    }

    @Test(arguments: ["apple.com docs", "x.ai", "Email acme.co about invoice", "see example.com/x"])
    func bareDomainsWithoutWwwStayText(_ title: String) {
        #expect(TodoTitlePart.parts(of: title) == [.text(title)])
    }

    @Test func aWwwLinkWithAnAccentKeepsItsLink() {
        let parts = TodoTitlePart.parts(of: "www.example.com/café")
        #expect(parts == [.link(label: "example.com/café", url: url("https://www.example.com/caf%C3%A9"))])
    }

    @Test func aLongLabelIsCutWithAnEllipsis() {
        let link = "https://example.com/" + String(repeating: "a", count: 36)
        let expected = "example.com/" + String(repeating: "a", count: 19) + "…"
        #expect(TodoTitlePart.parts(of: link) == [.link(label: expected, url: url(link))])
        #expect(expected.count == Limits.todoLinkLabelMax)
    }

    @Test func aLabelAtTheLimitIsNotCut() {
        let path = String(repeating: "b", count: 20)
        let link = "https://example.com/" + path
        #expect(TodoTitlePart.parts(of: link) == [.link(label: "example.com/" + path, url: url(link))])
    }

    @Test func theLabelLimitIs32() {
        #expect(Limits.todoLinkLabelMax == 32)
    }
}
