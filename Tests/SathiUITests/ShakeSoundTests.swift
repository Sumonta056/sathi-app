import SathiCore
@testable import SathiUI
import Testing

@Suite("Shake sound")
struct ShakeSoundTests {
    @Test func waterTinks() {
        #expect(ShakeSound.sound(for: .water) == .tink)
    }

    @Test(arguments: [HabitID.reading, .meditation])
    func calmHabitsShakeInSilence(_ id: HabitID) {
        #expect(ShakeSound.sound(for: id) == nil)
    }
}
