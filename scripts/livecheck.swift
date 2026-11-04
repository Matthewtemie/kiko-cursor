#!/usr/bin/env swift
// Checks the running app from outside its process, by asking the window system what
// is really on screen. Usage: livecheck <path to KikoCursor binary>
//
// It moves the real mouse for a few seconds (it never clicks) and puts it back.
import AppKit

typealias IsVisible = @convention(c) () -> Int32
let isVisibleFn = unsafeBitCast(dlsym(dlopen(nil, RTLD_NOW), "CGCursorIsVisible"), to: IsVisible.self)
func cursorVisible() -> Bool { isVisibleFn() != 0 }

let cursorLevel = Int(CGWindowLevelForKey(.cursorWindow))
var failures = 0

func expect(_ ok: Bool, _ name: String, _ detail: @autoclosure () -> String = "") {
    let extra = detail()
    print(ok ? "  ok    \(name) \(extra)" : "  FAIL  \(name) \(extra)")
    if !ok { failures += 1 }
}

func overlayFrame(pid: pid_t) -> CGRect? {
    let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
    for w in list where (w[kCGWindowOwnerPID as String] as? pid_t) == pid && (w[kCGWindowLayer as String] as? Int) == cursorLevel {
        if let b = w[kCGWindowBounds as String] as? NSDictionary { return CGRect(dictionaryRepresentation: b) }
    }
    return nil
}

func mouse() -> CGPoint { CGEvent(source: nil)?.location ?? .zero }
func wait(_ s: TimeInterval) { RunLoop.current.run(until: Date().addingTimeInterval(s)) }

guard CommandLine.arguments.count > 1 else {
    print("usage: livecheck <KikoCursor binary>")
    exit(2)
}

/// On macOS 26 menu bar items are windows hosted by Control Centre, not by their own app.
/// This asks for all windows, because the menu bar counts as off screen in a full-screen
/// Space. Counting these before and after launch doesn't work: the last item to quit stays
/// listed until the next one replaces it.
func menuBarItems() -> [CGRect] {
    let statusLevel = Int(CGWindowLevelForKey(.statusWindow))
    let list = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as? [[String: Any]] ?? []
    return list.compactMap { w -> CGRect? in
        guard (w[kCGWindowLayer as String] as? Int) == statusLevel,
              (w[kCGWindowOwnerName as String] as? String)?.hasPrefix("Control Cent") == true,
              let b = w[kCGWindowBounds as String] as? NSDictionary,
              let rect = CGRect(dictionaryRepresentation: b), rect.width < 200
        else { return nil }
        return rect
    }
}

// With the screen locked or the display asleep no frames are drawn, so most of this would fail
// for a reason that has nothing to do with the app.
let session = CGSessionCopyCurrentDictionary() as? [String: Any] ?? [:]
if session["CGSSessionScreenIsLocked"] as? Bool == true || CGDisplayIsAsleep(CGMainDisplayID()) != 0 {
    print("not run: the screen is locked or the display is asleep")
    exit(2)
}

let start = mouse()
let bounds = NSScreen.main!.frame
print("displays: \(NSScreen.screens.map { "\($0.frame) scale \($0.backingScaleFactor)" })")

let app = Process()
app.executableURL = URL(fileURLWithPath: CommandLine.arguments[1])
app.arguments = ["--exit-after", "40"]
try! app.run()
let pid = app.processIdentifier
defer { CGWarpMouseCursorPosition(start) }
wait(1.2)

print("launch")
expect(app.isRunning, "app is running")
expect(overlayFrame(pid: pid) != nil, "overlay window is on screen at cursor level")
expect(!cursorVisible(), "system pointer is hidden, with another app frontmost",
       "(front: \(NSWorkspace.shared.frontmostApplication?.localizedName ?? "?"))")

print("following the mouse")
var worst: CGFloat = 0
var samples = 0
var warpMiss: CGFloat = 0
var centres: Set<String> = []
let spots: [CGPoint] = [
    CGPoint(x: bounds.midX, y: bounds.midY),
    CGPoint(x: 200, y: 200),
    CGPoint(x: bounds.maxX - 200, y: 300),
    CGPoint(x: bounds.maxX - 10, y: bounds.maxY - 10),
    CGPoint(x: 10, y: 10),
    CGPoint(x: bounds.midX, y: bounds.maxY - 300),
]
for p in spots {
    CGWarpMouseCursorPosition(p)
    wait(0.03)
    let landed = mouse()
    warpMiss = max(warpMiss, hypot(landed.x - p.x, landed.y - p.y))

    // Two things can make a good window look wrong, so keep looking for up to 3 s. A hand on
    // the mouse moves it during the 14 ms a window list takes, so a reading only counts if
    // the mouse held still across it. A Spaces swipe reports windows offset by whole desktops
    // (about 1576 pt each here) until it settles. A window that is really in the wrong place
    // stays wrong through all of this, and fails.
    var err = CGFloat.infinity
    var settled: CGRect?
    var at = landed
    for _ in 0..<30 {
        let before = mouse()
        wait(0.1)
        guard let f = overlayFrame(pid: pid) else { continue }
        at = mouse()
        guard hypot(at.x - before.x, at.y - before.y) < 0.5 else { continue }
        settled = f
        err = hypot(f.midX - at.x, f.midY - at.y)
        if err <= 1 { break }
    }
    guard let f = settled else {
        print("  note  the mouse never held still at \(p), so that spot wasn't judged")
        continue
    }
    if err > 1 {
        print("  off: asked \(p), mouse \(at), window \(f)")
    }
    worst = max(worst, err)
    centres.insert("\(f.midX),\(f.midY)")
    samples += 1
}
expect(samples >= spots.count - 1, "saw the window at the positions", "(\(samples)/\(spots.count))")
// Without these two, a mouse that never moved would pass the accuracy check below.
// The margin is for a hand on the mouse during the 30 ms after each move.
expect(warpMiss <= 60, "the mouse really went to each position", "(worst miss \(String(format: "%.2f", warpMiss)) pt)")
expect(centres.count == samples, "the window really moved each time", "(\(centres.count) distinct positions)")
expect(worst <= 1.0, "window centre stays on the real mouse position", "(worst \(String(format: "%.2f", worst)) pt)")
CGWarpMouseCursorPosition(start)
wait(0.2)

print("toggle")
kill(pid, SIGUSR1)
wait(0.4)
expect(overlayFrame(pid: pid) == nil, "toggle off removes the overlay")
expect(cursorVisible(), "toggle off brings the system pointer back")
kill(pid, SIGUSR1)
wait(0.4)
expect(overlayFrame(pid: pid) != nil, "toggle on restores the overlay")
expect(!cursorVisible(), "toggle on hides the system pointer again")

print("crash safety")
kill(pid, SIGKILL)
app.waitUntilExit()
wait(0.3)
expect(cursorVisible(), "killing the app outright restores the system pointer")
expect(overlayFrame(pid: pid) == nil, "and removes the overlay")

print("clean quit")
let again = Process()
again.executableURL = URL(fileURLWithPath: CommandLine.arguments[1])
again.arguments = ["--exit-after", "1"]
try! again.run()
wait(0.7)
expect(!cursorVisible(), "hidden while running")
again.waitUntilExit()
wait(0.3)
expect(again.terminationStatus == 0, "exits cleanly", "(status \(again.terminationStatus))")
expect(cursorVisible(), "pointer is back after quitting")

print("when the system brings the pointer back")
let forced = Process()
forced.executableURL = URL(fileURLWithPath: CommandLine.arguments[1])
forced.arguments = ["--exit-after", "4", "--test-unhide-every", "0.6"]
try! forced.run()
wait(0.8)
var spellStart: Date?
var worstSpell = 0.0
var returns = 0
let spellsEnd = Date().addingTimeInterval(2.6)
while Date() < spellsEnd {
    if cursorVisible() {
        if spellStart == nil { spellStart = Date() }
    } else if let s = spellStart {
        worstSpell = max(worstSpell, Date().timeIntervalSince(s))
        returns += 1
        spellStart = nil
    }
    usleep(2000)
}
forced.waitUntilExit()
wait(0.3)
expect(returns >= 2, "the test hook brought it back", "(\(returns) times)")
expect(worstSpell < 0.15, "it is hidden again within 150 ms", "(worst \(Int(worstSpell * 1000)) ms)")

print("menu bar")
let probe = Process()
probe.executableURL = URL(fileURLWithPath: CommandLine.arguments[1])
probe.arguments = ["--exit-after", "2.2", "--print-status"]
let pipe = Pipe()
probe.standardOutput = pipe
try! probe.run()
wait(1.6)
let hosted = menuBarItems()
probe.waitUntilExit()
let report = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
let numbers = report.split(whereSeparator: \.isWhitespace).compactMap { Double($0) }
if numbers.count == 4, let screen = NSScreen.main {
    let item = CGRect(x: numbers[0], y: numbers[1], width: numbers[2], height: numbers[3])
    // On a notched display, items pushed out of the area right of the notch can't be seen.
    let area = screen.auxiliaryTopRightArea ?? screen.frame
    expect(item.minX >= area.minX && item.maxX <= area.maxX, "item is in the visible area, clear of any notch",
           "(x \(Int(item.minX))-\(Int(item.maxX)), visible from x \(Int(area.minX)))")
    expect(hosted.contains { abs($0.minX - item.minX) < 3 && abs($0.width - item.width) < 3 }, "Control Centre has a window there for it")
} else {
    expect(false, "app reported its menu bar item", "(got: \(report))")
}

print(failures == 0 ? "live checks passed" : "\(failures) live check(s) FAILED")
exit(failures == 0 ? 0 : 1)
