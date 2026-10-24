import SwiftUI
import AppKit

@MainActor
func closeMenuBarWindow() {
    NSApp.keyWindow?.close()
}

// MARK: - Menu bar label

@MainActor
struct StatusLabel: View {
    @ObservedObject var engine: Engine
    var body: some View {
        HStack(spacing: 4) {
            if engine.statusIsBook {
                Image(systemName: "book.closed.fill")
            } else {
                Image(nsImage: engine.statusIcon)
            }
            Text(engine.statusText).monospacedDigit()
        }
    }
}

// MARK: - Menu bar panel

@MainActor
struct MenuPanel: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Sathi").font(.system(size: 18, weight: .semibold, design: .rounded))
                Spacer()
                Text(e.now.formatted(.dateTime.weekday(.wide).day().month()))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            ForEach(HabitID.allCases) { id in
                if e.enabled(id) { HabitRow(id: id) }
            }
            Divider().padding(.top, 2)
            MenuItem(title: e.pausedUntil == nil ? "Pause reminders for 1 hour" : "Resume reminders") {
                if e.pausedUntil == nil { e.pause(hours: 1) } else { e.resume() }
            }
            MenuItem(title: "Settings…") {
                closeMenuBarWindow()
                e.ui.showSettings()
            }
            MenuItem(title: "Quit Sathi") { NSApp.terminate(nil) }
        }
        .padding(14)
        .frame(width: 340)
    }
}

@MainActor
struct HabitRow: View {
    @EnvironmentObject var e: Engine
    let id: HabitID

    var body: some View {
        HStack(spacing: 12) {
            BuddyView(kind: id.kind, mood: e.mood(id), level: e.waterLevel)
                .frame(width: 44, height: 54)
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(id.name).font(.system(size: 15, weight: .semibold, design: .rounded))
                    Spacer()
                    Text(e.pill(id))
                        .font(.system(size: 11, weight: .semibold))
                        .monospacedDigit()
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .foregroundStyle(due ? Color.white : Color.secondary)
                        .background(Capsule().fill(due ? (id == .water ? Palette.waterDeep : Palette.bookDeep) : Color.primary.opacity(0.07)))
                }
                ProgressBar(value: e.progress(id), tint: id == .water ? Palette.water : Palette.book)
                Text(e.subtitle(id))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Button(id == .water ? "+1 glass" : "Read now") {
                closeMenuBarWindow()
                if id == .water { e.logWater(1) } else { e.startReading() }
            }
            .buttonStyle(MiniButton())
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.primary.opacity(0.05)))
    }

    private var due: Bool { e.isActive(id) || e.queue.contains(id) }
}

struct MenuItem: View {
    let title: String
    let action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .foregroundStyle(hover ? Color.white : Color.primary)
                .background(RoundedRectangle(cornerRadius: 6).fill(hover ? Color.accentColor : Color.clear))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
    }
}

// MARK: - Reminder bubble

@MainActor
struct BubbleView: View {
    @EnvironmentObject var e: Engine
    let id: HabitID
    let level: Level

    @State private var container: Container = .glass
    @State private var bottleNow: Double = 1
    @State private var shakes: CGFloat = 0
    private let shakeTimer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()

    private var accent: Color { id == .water ? Palette.water : Palette.book }
    private var deep: Color { id == .water ? Palette.waterDeep : Palette.bookDeep }
    private var drunk: Double { (e.data.bottleLevel - bottleNow) * e.data.prefs.bottleSizeGlasses }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            if id == .water { waterSection } else { readingSection }
            actions
            if level == .persist { warn }
            IgnoreBar(accent: accent)
        }
        .padding(18)
        .frame(width: 380)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Palette.card))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(level == .persist ? accent : Color.black.opacity(0.08), lineWidth: level == .persist ? 2 : 1)
        )
        .shadow(color: Color.black.opacity(0.28), radius: 18, x: 0, y: 10)
        .modifier(Shake(amount: shakes))
        .padding(24)
        .foregroundStyle(Palette.ink)
        .onAppear {
            container = e.data.prefs.defaultContainer
            bottleNow = e.data.bottleLevel
        }
        .onReceive(shakeTimer) { _ in
            guard level == .persist else { return }
            withAnimation(.linear(duration: 0.6)) { shakes += 1 }
            e.play("Tink")
        }
    }

    private var eyebrow: String {
        let time = Date().formatted(date: .omitted, time: .shortened)
        if level == .persist {
            return "STILL WAITING · SNOOZED \(e.state(id).snoozes)× · \(time)"
        }
        return "\(id.name.uppercased()) · \(time)"
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            BuddyView(kind: id.kind, mood: .thirsty, level: 0.06)
                .frame(width: 78, height: 96)
            VStack(alignment: .leading, spacing: 5) {
                Text(eyebrow)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(deep)
                Text(e.copy.title)
                    .font(.system(size: 21, weight: .semibold, design: .rounded))
                    .fixedSize(horizontal: false, vertical: true)
                Text(e.copy.body)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var waterSection: some View {
        VStack(spacing: 12) {
            Picker("", selection: $container) {
                Text("Glass").tag(Container.glass)
                Text("Sip bottle").tag(Container.bottle)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            if container == .glass {
                HStack(spacing: 8) {
                    glassButton(0.25, "A few sips")
                    glassButton(0.5, "Half")
                    glassButton(1, "Full glass")
                }
                .frame(maxHeight: .infinity)
            } else {
                bottleRow
            }
        }
        .frame(height: 196)
    }

    private func glassButton(_ g: Double, _ label: String) -> some View {
        Button {
            e.logWater(g)
        } label: {
            VStack(spacing: 6) {
                GlassIcon(fill: g).frame(width: 30, height: 36)
                Text(label).font(.system(size: 13, weight: .semibold))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(Palette.waterDeep)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Palette.waterDeep.opacity(0.2), lineWidth: 1.5))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var bottleRow: some View {
        HStack(spacing: 16) {
            BottleView(was: e.data.bottleLevel, now: $bottleNow)
                .frame(width: 76, height: 150)
            VStack(alignment: .leading, spacing: 8) {
                Text("Drag the line to where your water is now.")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.ink2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(drunk < 0.12 ? "Drag down to log" : "About \(Fmt.glasses(drunk))")
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.waterDeep)
                Button("Log it") { e.logBottle(newLevel: bottleNow) }
                    .buttonStyle(PillButton(kind: .primary, height: 38))
                    .disabled(drunk < 0.12)
                    .opacity(drunk < 0.12 ? 0.45 : 1)
                Button("I refilled it") {
                    e.refillBottle()
                    bottleNow = 1
                }
                .buttonStyle(PillButton(kind: .ghost, height: 38))
            }
        }
    }

    private var readingSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "book")
                .font(.system(size: 24))
                .foregroundStyle(Palette.bookDeep)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(e.data.prefs.readingSessionMinutes)-minute session")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Text("Open your book, then start the timer. Sathi keeps other reminders quiet until you finish.")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(hex: 0xFFF8EC)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Palette.bookDeep.opacity(0.18), lineWidth: 1))
    }

    private var actions: some View {
        HStack(spacing: 8) {
            if id == .reading {
                Button("Start \(e.data.prefs.readingSessionMinutes)-min timer") { e.startReading() }
                    .buttonStyle(PillButton(kind: .primary))
                    .layoutPriority(1)
            }
            Button(e.snoozeLabel(id)) { e.snooze() }
                .buttonStyle(PillButton(kind: .ghost))
        }
    }

    private var warn: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.fill").foregroundStyle(deep)
            Text(e.warnText(id)).font(.system(size: 12.5)).foregroundStyle(Palette.ink2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(accent.opacity(0.14)))
    }
}

@MainActor
struct IgnoreBar: View {
    @EnvironmentObject var e: Engine
    let accent: Color

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { tl in
            let total = Double(max(1, e.data.prefs.ignoreMinutes * 60))
            let left = max(0, e.ignoreDeadline.timeIntervalSince(tl.date))
            VStack(alignment: .leading, spacing: 6) {
                ProgressBar(value: left / total, tint: accent, height: 4, track: Color.black.opacity(0.08))
                Text("Ignore me for \(Fmt.clock(left)) more and it counts as a snooze")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Palette.muted)
                    .monospacedDigit()
            }
        }
    }
}

// MARK: - Lock screen

struct LockShade: View {
    var body: some View {
        Palette.night.opacity(0.92).ignoresSafeArea()
    }
}

@MainActor
struct LockView: View {
    @EnvironmentObject var e: Engine
    let id: HabitID

    @State private var pressStart: Date?
    @State private var done = false
    @State private var confirmSkip = false

    var body: some View {
        TimelineView(.animation) { tl in
            let p = done ? 1 : (pressStart.map { min(1, tl.date.timeIntervalSince($0) / 3) } ?? 0)
            ZStack {
                Palette.night.opacity(0.9).ignoresSafeArea()
                VStack(spacing: 14) {
                    Text(tl.date.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 80, weight: .medium, design: .rounded))
                        .monospacedDigit()
                    Text(tl.date.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                        .font(.system(size: 15))
                        .opacity(0.75)
                    BuddyView(kind: id.kind, mood: p >= 1 ? .cheer : (p > 0 ? .thirsty : .sad), level: p)
                        .frame(width: 150, height: 186)
                        .padding(.top, 8)
                    Text("SNOOZED TWICE · SCREEN PAUSED")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.8)
                        .foregroundStyle(Palette.waterMid)
                    Text(id == .water ? "Fota is drying up. Go get some water." : "Boi has waited long enough. Get your book.")
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .multilineTextAlignment(.center)
                    Text(id == .water
                         ? "Take a few sips, then press and hold for 3 seconds. Your screen comes back right after."
                         : "Open your book, then press and hold for 3 seconds to start your reading timer.")
                        .font(.system(size: 16))
                        .foregroundStyle(Color(hex: 0xCFE3F2))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 460)
                    holdButton(p)
                    Text(p >= 1 ? "Thank you." : (p > 0 ? "Keep holding…" : "Press and hold."))
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: 0xA9C7DD))
                    skipArea
                }
                .foregroundStyle(.white)
                .frame(maxWidth: 580)
                .padding(24)
            }
        }
    }

    private func holdButton(_ p: Double) -> some View {
        ZStack {
            Circle().fill(Color.white.opacity(pressStart != nil ? 0.22 : 0.12))
            Circle().stroke(Color.white.opacity(0.18), lineWidth: 8)
            Circle()
                .trim(from: 0, to: CGFloat(p))
                .stroke(Palette.waterMid, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(p >= 1 ? "Done" : (p > 0 ? "\(Int(ceil((1 - p) * 3)))" : "Hold"))
                .font(.system(size: 18, weight: .semibold, design: .rounded))
        }
        .frame(width: 136, height: 136)
        .scaleEffect(pressStart != nil ? 0.95 : 1)
        .contentShape(Circle())
        .onLongPressGesture(minimumDuration: 3, maximumDistance: 80, pressing: { pressing in
            if !done { pressStart = pressing ? Date() : nil }
        }, perform: {
            done = true
            pressStart = nil
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 450_000_000)
                e.lockConfirmed(id)
            }
        })
        .padding(.top, 6)
    }

    @ViewBuilder
    private var skipArea: some View {
        if confirmSkip {
            VStack(spacing: 10) {
                Text("Skipping resets your \(e.streak(id))-day streak to zero.")
                    .font(.system(size: 13.5))
                HStack(spacing: 8) {
                    Button("Keep my streak") { confirmSkip = false }
                        .buttonStyle(PillButton(kind: .onDark, height: 38))
                    Button("Skip anyway") { e.emergencySkip(id) }
                        .buttonStyle(PillButton(kind: .danger, height: 38))
                }
                .frame(width: 320)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.08)))
        } else {
            Button {
                confirmSkip = true
            } label: {
                Text("Emergency skip").underline().font(.system(size: 13)).foregroundStyle(Color(hex: 0xA9C7DD))
            }
            .buttonStyle(.plain)
            .padding(8)
        }
    }
}

// MARK: - Reading session

@MainActor
struct SessionView: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { tl in
            let total = max(1, e.sessionEnd.timeIntervalSince(e.sessionStart))
            let left = max(0, e.sessionEnd.timeIntervalSince(tl.date))
            VStack(spacing: 10) {
                BuddyView(kind: .book, mood: .reading)
                    .frame(width: 96, height: 119)
                Text("READING · DO NOT DISTURB")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(Palette.bookDeep)
                Text(Fmt.clock(left))
                    .font(.system(size: 54, weight: .medium, design: .rounded))
                    .monospacedDigit()
                ProgressBar(value: 1 - left / total, tint: Palette.book, height: 8, track: Palette.bookDeep.opacity(0.12))
                Text("Boi is reading with you. Water reminders wait until the timer ends.")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.ink2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                if e.queue.contains(.water) {
                    Text("Fota is waiting for you after this")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Palette.waterDeep)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Palette.water.opacity(0.14)))
                }
                Button("Stop early (won't count)") { e.stopSession() }
                    .buttonStyle(PillButton(kind: .ghost))
            }
            .padding(24)
            .frame(width: 340)
            .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Palette.paper))
            .shadow(color: Color.black.opacity(0.3), radius: 24, x: 0, y: 12)
            .padding(30)
            .foregroundStyle(Palette.ink)
        }
    }
}

// MARK: - Celebration

@MainActor
struct CelebrateView: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let c = e.celebration
        VStack(spacing: 10) {
            BuddyView(kind: c.id.kind, mood: .cheer, level: 1)
                .frame(width: 110, height: 136)
            Text(c.id == .water ? "+\(Fmt.glasses(c.amount))" : "\(Int(c.amount)) min read")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Capsule().fill(c.id == .water ? Palette.waterDeep : Palette.bookDeep))
            Text(c.title)
                .font(.system(size: 26, weight: .semibold, design: .rounded))
            Text(subtitle(c))
                .font(.system(size: 14))
                .foregroundStyle(Palette.ink2)
            if c.id == .water { waterRow } else { weekRow }
            Button("Back to work") { e.endCelebrate() }
                .buttonStyle(PillButton(kind: .primary))
                .padding(.top, 4)
        }
        .padding(.horizontal, 24)
        .padding(.top, 26)
        .padding(.bottom, 20)
        .frame(width: 360)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Palette.card))
        .shadow(color: Color.black.opacity(0.3), radius: 24, x: 0, y: 12)
        .padding(30)
        .foregroundStyle(Palette.ink)
    }

    private func subtitle(_ c: Celebration) -> String {
        if c.id == .water {
            return "\(Fmt.count(e.glassesToday)) of \(Int(e.data.prefs.dailyGoalGlasses)) glasses today · \(e.streak(.water))-day streak"
        }
        return "\(e.streak(.reading))-day reading streak"
    }

    private var waterRow: some View {
        let goal = max(1, Int(e.data.prefs.dailyGoalGlasses))
        let total = e.glassesToday
        return HStack(spacing: 4) {
            ForEach(0..<goal, id: \.self) { i in
                let f = max(0, min(1, total - Double(i)))
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 5).fill(Palette.ink.opacity(0.08))
                    RoundedRectangle(cornerRadius: 5).fill(Palette.water).frame(height: CGFloat(26 * f))
                }
                .frame(height: 26)
            }
        }
        .padding(.vertical, 6)
    }

    private var weekRow: some View {
        let weekday = (Calendar.current.component(.weekday, from: Date()) + 5) % 7 // Monday = 0
        let streak = e.streak(.reading)
        let labels = ["M", "T", "W", "T", "F", "S", "S"]
        return HStack(spacing: 5) {
            ForEach(0..<7, id: \.self) { i in
                let on = i <= weekday && i > weekday - streak
                Text(labels[i])
                    .font(.system(size: 11, weight: .semibold))
                    .frame(maxWidth: .infinity, minHeight: 30)
                    .foregroundStyle(on ? Color.white : Palette.muted)
                    .background(Capsule().fill(on ? Palette.book : Palette.ink.opacity(0.08)))
            }
        }
        .padding(.vertical, 6)
    }
}
