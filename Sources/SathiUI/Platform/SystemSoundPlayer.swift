import AppKit
import SathiCore

package struct SystemSoundPlayer: SoundPlayer {
    package init() {}

    package func play(_ sound: SoundName) {
        NSSound(named: NSSound.Name(sound.rawValue))?.play()
    }

    package func beep() {
        NSSound.beep()
    }
}
