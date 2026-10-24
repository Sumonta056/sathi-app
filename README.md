# Sathi

A menu bar app with two buddies that won't let you skip:

- **Fota** (water): pops up every 2 hours between 9:30 and 18:30. Log with a glass (a few sips / half / full) or drag the line on your sip bottle.
- **Boi** (reading): pops up at 22:00 and only counts when a 15-minute reading timer finishes.

If you ignore a buddy it escalates: popup → stays on top and shakes → (Strict) full-screen lock you unlock by holding a button for 3 seconds.

## Install (one time, about 1 minute)

Needs macOS 13 Ventura or newer.

1. Install Apple's command line tools if you don't have them:
   ```
   xcode-select --install
   ```
2. Unzip this folder, open Terminal in it, and run:
   ```
   chmod +x build.sh
   ./build.sh --install
   ```
3. A drop appears in your menu bar. Open **Settings…** from it and turn on **Open Sathi when my Mac starts**.

To test right away: Settings → **Show water reminder now**. Snooze twice to see the lock screen.

## Change things

Everything (times, interval, glass/bottle, bottle size, goal, strictness, snooze length, sound) is in Settings. Data is stored locally in UserDefaults (`com.mridul.sathi`).

## Files

- `Engine.swift`: scheduler, queue and escalation
- `UIController.swift`: bubble, lock, reading and celebration windows
- `Views.swift`: all SwiftUI screens
- `Buddy.swift`: Fota, Boi, glass and bottle drawings
- `SettingsView.swift`, `Model.swift`, `Theme.swift`, `SathiApp.swift`

Adding a habit later means adding a case to `HabitID`, its prefs, a buddy drawing and its popup section.
