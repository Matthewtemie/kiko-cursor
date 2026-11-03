import AppKit

let args = CommandLine.arguments

if let i = args.firstIndex(of: "--sheet"), i + 1 < args.count {
    Sheet.render(to: URL(fileURLWithPath: args[i + 1]))
    exit(0)
}

if let i = args.firstIndex(of: "--portrait"), i + 1 < args.count {
    Sheet.portrait(to: URL(fileURLWithPath: args[i + 1]))
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
    Sheet.bench()
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
