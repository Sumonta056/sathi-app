import CoreGraphics
@testable import SathiUI
import Testing

@Suite("Center stack")
struct CenterStackTests {
    private let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
    private let note = CGSize(width: 380, height: 100)
    private let gap: CGFloat = 12

    @Test func theNoteSitsAboveTheOpenPrompt() {
        let prompt = CGRect(x: 280, y: 250, width: 880, height: 400)
        let origin = CenterStack.noteOrigin(note: note, prompt: prompt, screen: screen, gap: gap)
        #expect(origin == CGPoint(x: 530, y: 662))
    }

    @Test func theNoteSitsBelowThePromptWhenThereIsNoRoomAbove() {
        let prompt = CGRect(x: 280, y: 400, width: 880, height: 450)
        let origin = CenterStack.noteOrigin(note: note, prompt: prompt, screen: screen, gap: gap)
        #expect(origin == CGPoint(x: 530, y: 288))
    }

    @Test func theNoteSitsAtTheCenterWhenThereIsNoRoomAboveOrBelow() {
        let prompt = CGRect(x: 280, y: 50, width: 880, height: 800)
        let origin = CenterStack.noteOrigin(note: note, prompt: prompt, screen: screen, gap: gap)
        #expect(origin == CGPoint(x: 530, y: 400))
    }

    @Test func theNoteSitsAtTheCenterWithNoPrompt() {
        let origin = CenterStack.noteOrigin(note: note, prompt: nil, screen: screen, gap: gap)
        #expect(origin == CGPoint(x: 530, y: 400))
    }

    @Test func theNoteCentersOnAScreenThatDoesNotStartAtZero() {
        let right = CGRect(x: 1440, y: 100, width: 1920, height: 1080)
        let origin = CenterStack.noteOrigin(note: note, prompt: nil, screen: right, gap: gap)
        #expect(origin == CGPoint(x: 2210, y: 590))
    }

    @Test func theMouseScreenIsTheScreenUnderThePointer() {
        let left = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let right = CGRect(x: 1440, y: 0, width: 1920, height: 1080)
        #expect(CenterStack.mouseScreenFrame(screens: [left, right], mouse: CGPoint(x: 2000, y: 500)) == right)
        #expect(CenterStack.mouseScreenFrame(screens: [left, right], mouse: CGPoint(x: 100, y: 500)) == left)
    }

    @Test func aPointerOutsideEveryScreenPicksTheFirstScreen() {
        let left = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let right = CGRect(x: 1440, y: 0, width: 1920, height: 1080)
        #expect(CenterStack.mouseScreenFrame(screens: [left, right], mouse: CGPoint(x: -50, y: 5000)) == left)
    }
}
