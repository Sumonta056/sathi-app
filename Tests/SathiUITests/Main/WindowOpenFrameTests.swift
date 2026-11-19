import AppKit
import SathiCore
import SathiTestSupport
@testable import SathiUI
import Testing

@Suite("Window open frame")
struct WindowOpenFrameTests {
    private let screenA = CGRect(x: 0, y: 40, width: 1440, height: 835)
    private let screenB = CGRect(x: 1440, y: 0, width: 1920, height: 1055)
    private let size = UIMetrics.mainWindowSize

    private func open(_ saved: CGRect?, screens: [CGRect], pointer: CGRect) -> CGRect {
        WindowFit.openFrame(saved: saved, screens: screens, pointer: pointer, defaultSize: size)
    }

    @Test func firstOpenIsTheDefaultSizeCenteredOnThePointerDisplay() {
        let frame = open(nil, screens: [screenA, screenB], pointer: screenB)
        #expect(frame.size == size)
        #expect(frame.midX == screenB.midX)
        #expect(frame.midY == screenB.midY)
    }

    @Test func firstOpenOnASmallDisplayShrinksToFit() {
        let tiny = CGRect(x: 0, y: 0, width: 1000, height: 600)
        let frame = open(nil, screens: [tiny], pointer: tiny)
        #expect(frame == tiny)
    }

    @Test func aRememberedFrameOnAScreenIsKept() {
        let saved = CGRect(x: 1600, y: 100, width: 900, height: 700)
        #expect(open(saved, screens: [screenA, screenB], pointer: screenA) == saved)
    }

    @Test func aRememberedFullScreenAreaIsKept() {
        #expect(open(screenA, screens: [screenA, screenB], pointer: screenB) == screenA)
    }

    @Test func aSliverOverlapMovesFullyOntoThePointerDisplay() {
        let saved = CGRect(x: 1430, y: 100, width: 900, height: 600)
        let frame = open(saved, screens: [screenA], pointer: screenA)
        #expect(screenA.contains(frame))
        #expect(frame.size == saved.size)
    }

    @Test func aFrameWhoseTitleBarIsAboveTheScreenMovesOntoThePointerDisplay() {
        let saved = CGRect(x: 100, y: screenA.maxY - 50, width: 900, height: 600)
        let frame = open(saved, screens: [screenA], pointer: screenA)
        #expect(screenA.contains(frame))
    }

    @Test func anOversizedFrameShrinksToItsDisplay() {
        let saved = CGRect(x: 0, y: screenA.maxY - 1400, width: 2400, height: 1400)
        #expect(open(saved, screens: [screenA], pointer: screenA) == screenA)
    }

    @Test func aFrameOnAGoneDisplayMovesOntoThePointerDisplay() {
        let gone = CGRect(x: -1280, y: 100, width: 1000, height: 600)
        let frame = open(gone, screens: [screenA, screenB], pointer: screenB)
        #expect(screenB.contains(frame))
        #expect(frame.size == gone.size)
    }

    @Test func aFrameMostlyOnItsDisplayIsKeptWhereItIs() {
        let saved = CGRect(x: 800, y: 100, width: 900, height: 600)
        #expect(open(saved, screens: [screenA], pointer: screenA) == saved)
    }

    @Test func aRememberedFrameOffEveryScreenMovesOntoThePointerDisplay() {
        let saved = CGRect(x: 4000, y: 100, width: 900, height: 700)
        let frame = open(saved, screens: [screenA], pointer: screenA)
        #expect(screenA.contains(frame))
        #expect(frame.size == saved.size)
    }

    @Test func aRememberedFrameOffEveryScreenShrinksToFitThePointerDisplay() {
        let saved = CGRect(x: 4000, y: 0, width: 1920, height: 1055)
        let frame = open(saved, screens: [screenA], pointer: screenA)
        #expect(frame == screenA)
    }
}

@MainActor
@Suite("Main window frame memory")
struct MainFrameMemoryTests {
    private func memory() -> MainFrameMemory {
        MainFrameMemory(name: "SathiTests-\(UUID().uuidString)")
    }

    private func window(_ frame: CGRect) -> NSWindow {
        NSWindow(contentRect: frame, styleMask: [.titled, .resizable], backing: .buffered, defer: true)
    }

    @Test func nothingIsRememberedAtFirst() {
        #expect(memory().frame() == nil)
    }

    @Test(.enabled(if: NSScreen.main != nil))
    func aSavedFrameComesBackInANewWindow() throws {
        let m = memory()
        defer { m.forget() }
        let visible = try #require(NSScreen.main?.visibleFrame)
        let saved = CGRect(x: visible.minX + 120, y: visible.minY + 80, width: 900, height: 640)
        let first = window(saved)
        first.setFrame(saved, display: false)
        m.save(first)
        #expect(m.frame() == first.frame)
    }

    @Test(.enabled(if: NSScreen.main != nil))
    func aRealOpenUsesTheRememberedFrame() throws {
        let m = memory()
        defer { m.forget() }
        guard let visible = NSScreen.main?.visibleFrame else { return }
        let saved = visible.insetBy(dx: 60, dy: 60)
        let old = window(saved)
        old.setFrame(saved, display: false)
        m.save(old)
        let h = EngineHarness()
        let c = UIController()
        c.mainFrames = m
        c.mainWindowShown = { _ in }
        c.engine = h.engine
        c.showMain(.dashboard(.day))
        let shown = try #require(c.mainWindow)
        #expect(shown.frame == saved)
        shown.close()
    }

    @Test(.enabled(if: NSScreen.main != nil))
    func anOffScreenMemoryOpensAndIsSavedOnScreen() throws {
        let m = memory()
        defer { m.forget() }
        let far = window(CGRect(x: 0, y: 0, width: 900, height: 600))
        far.setFrame(CGRect(x: 90000, y: 90000, width: 900, height: 600), display: false)
        m.save(far)
        let h = EngineHarness()
        let c = UIController()
        c.mainFrames = m
        c.mainWindowShown = { _ in }
        c.engine = h.engine
        c.showMain(.dashboard(.day))
        let shown = try #require(c.mainWindow)
        #expect(NSScreen.screens.contains { $0.visibleFrame.contains(shown.frame) })
        #expect(m.frame() == shown.frame)
        shown.close()
    }
}
