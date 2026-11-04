import AppKit
import KikoCore

let args = CommandLine.arguments

// Without this, a mistyped flag would start the app for real and take over the pointer.
let knownFlags: Set<String> = ["--avatar", "--sheet", "--portrait", "--lineup", "--icon", "--check", "--bench", "--login-item",
                               "--exit-after", "--dump-frame", "--test-unhide-every", "--test-avatar-menu", "--test-core-video-clock", "--print-status"]
if let unknown = args.dropFirst().first(where: { $0.hasPrefix("--") && !knownFlags.contains($0) }) {
    print("unknown flag \(unknown); the flags are \(knownFlags.sorted().joined(separator: " "))")
    exit(2)
}
// Nor may a flag that's missing its value, or a single-dash typo. AppKit has -NS... arguments of its own.
let valueFlags: Set<String> = ["--avatar", "--sheet", "--portrait", "--lineup", "--icon", "--login-item", "--exit-after",
                               "--dump-frame", "--test-unhide-every", "--test-avatar-menu"]
for (i, arg) in args.enumerated().dropFirst() {
    if knownFlags.contains("-" + arg) {
        print("did you mean -\(arg)?")
        exit(2)
    }
    if valueFlags.contains(arg), i + 1 == args.count || args[i + 1].hasPrefix("--") {
        print("\(arg) needs a value")
        exit(2)
    }
    if ["--exit-after", "--test-unhide-every"].contains(arg), Double(args[i + 1]) == nil {
        print("\(arg) needs a number of seconds, not \(args[i + 1])")
        exit(2)
    }
}

// --avatar NAME picks who the sheets draw, and who this run shows, without saving the choice.
var chosenAvatar: Avatar?
if let i = args.firstIndex(of: "--avatar"), i + 1 < args.count {
    guard let avatar = Avatar(rawValue: args[i + 1]) else {
        print("unknown avatar \(args[i + 1]); pick one of \(Avatar.allCases.map(\.rawValue).joined(separator: ", "))")
        exit(2)
    }
    chosenAvatar = avatar
}

if let i = args.firstIndex(of: "--sheet"), i + 1 < args.count {
    Sheet.render(to: URL(fileURLWithPath: args[i + 1]), avatar: chosenAvatar ?? .kiko)
    exit(0)
}

if let i = args.firstIndex(of: "--portrait"), i + 1 < args.count {
    Sheet.portrait(to: URL(fileURLWithPath: args[i + 1]), avatar: chosenAvatar ?? .kiko)
    exit(0)
}

if let i = args.firstIndex(of: "--lineup"), i + 1 < args.count {
    Sheet.lineup(to: URL(fileURLWithPath: args[i + 1]))
    exit(0)
}

if let i = args.firstIndex(of: "--icon"), i + 1 < args.count {
    Sheet.icon(to: URL(fileURLWithPath: args[i + 1]))
    exit(0)
}

if args.contains("--check") {
    exit(Checks.run() ? 0 : 1)
}

if args.contains("--bench") {
    Sheet.bench(avatar: chosenAvatar ?? .kiko)
    exit(0)
}

// --login-item on|off|status does what the menu item does. It only works from inside the .app.
if let i = args.firstIndex(of: "--login-item"), i + 1 < args.count {
    do {
        if args[i + 1] != "status" {
            try LoginItem.set(args[i + 1] == "on")
        }
        print("login item: \(LoginItem.statusName)")
        exit(0)
    } catch {
        print("login item: failed: \(error.localizedDescription)")
        exit(1)
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
delegate.avatarForThisRun = chosenAvatar
delegate.forceCoreVideoClock = args.contains("--test-core-video-clock")
app.delegate = delegate

// --exit-after N quits on its own, so a test run can never strand the pointer.
if let i = args.firstIndex(of: "--exit-after"), i + 1 < args.count, let seconds = Double(args[i + 1]) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { NSApplication.shared.terminate(nil) }
}

// --dump-frame PATH writes the live view's frame to a PNG two seconds in.
if let i = args.firstIndex(of: "--dump-frame"), i + 1 < args.count {
    let url = URL(fileURLWithPath: args[i + 1])
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { delegate.dumpFrame(to: url) }
}

// --test-unhide-every N brings the system pointer back every N seconds, to time the re-hide.
if let i = args.firstIndex(of: "--test-unhide-every"), i + 1 < args.count, let seconds = Double(args[i + 1]) {
    Timer.scheduledTimer(withTimeInterval: seconds, repeats: true) { _ in delegate.simulatePointerReset() }
}

// --test-avatar-menu DIR picks each avatar through the real menu, then quits.
if let i = args.firstIndex(of: "--test-avatar-menu"), i + 1 < args.count {
    let dir = URL(fileURLWithPath: args[i + 1])
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        delegate.walkAvatarMenu(savingFramesTo: dir) { NSApplication.shared.terminate(nil) }
    }
}

// --print-status reports where the menu bar item landed, for scripts/livecheck.swift.
if args.contains("--print-status") {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        if let f = delegate.statusItemFrame {
            print("status-item \(f.minX) \(f.minY) \(f.width) \(f.height)")
            fflush(stdout)
        }
    }
}

app.run()
