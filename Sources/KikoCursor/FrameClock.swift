import AppKit
import CoreVideo
import QuartzCore

/// Calls back on the main thread once per display frame, less often while nothing is moving.
protocol FrameClock: AnyObject {
    var isPaused: Bool { get set }
    var isLively: Bool { get set }
    /// Says which display the window is on now, for a clock that can't work that out itself.
    func follow(_ screen: NSScreen?)
}

/// `forceCoreVideo` runs macOS 13's clock on a newer system, so that it can be tested there.
func makeFrameClock(for view: NSView, forceCoreVideo: Bool, onFrame: @escaping (CFTimeInterval) -> Void) -> FrameClock {
    if #available(macOS 14, *), !forceCoreVideo {
        return ViewLinkClock(view: view, onFrame: onFrame)
    }
    return CoreVideoClock(onFrame: onFrame)
}

@available(macOS 14, *)
private final class ViewLinkClock: NSObject, FrameClock {
    private static let livelyRate = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
    private static let idleRate = CAFrameRateRange(minimum: 24, maximum: 30, preferred: 30)

    private let onFrame: (CFTimeInterval) -> Void
    private var link: CADisplayLink?

    init(view: NSView, onFrame: @escaping (CFTimeInterval) -> Void) {
        self.onFrame = onFrame
        super.init()
        let displayLink = view.displayLink(target: self, selector: #selector(frame(_:)))
        displayLink.preferredFrameRateRange = Self.idleRate
        displayLink.isPaused = true
        displayLink.add(to: .main, forMode: .common)
        link = displayLink
    }

    var isPaused: Bool {
        get { link?.isPaused ?? true }
        set { link?.isPaused = newValue }
    }

    var isLively = false {
        didSet { link?.preferredFrameRateRange = isLively ? Self.livelyRate : Self.idleRate }
    }

    // A link made from a view follows that view's window.
    func follow(_ screen: NSScreen?) {}

    @objc private func frame(_ displayLink: CADisplayLink) {
        onFrame(displayLink.timestamp)
    }
}

/// macOS 13 has no CADisplayLink. A CVDisplayLink ticks on a thread of its own at the display's
/// full rate, whatever it's asked for, so this drops the frames it doesn't want and hands the
/// rest to the main thread. Nor does it look after itself the way a CADisplayLink does, so once
/// a second `check` stops it while the displays sleep and rebuilds it if the frames have stopped.
/// Without frames the pointer stays hidden with nothing drawn in its place.
private final class CoreVideoClock: FrameClock {
    // Under 1/120 of a second, so that the full rate of a 144 or 165 Hz display still counts. A
    // 240 Hz display gets every second tick. The idle one is a little under 1/30 of a second.
    private static let livelyInterval = 0.006
    private static let idleInterval = 1.0 / 30 - 0.001

    private let onFrame: (CFTimeInterval) -> Void
    private var link: CVDisplayLink?
    private var display = CGMainDisplayID()
    private var lastFrame: CFTimeInterval = 0
    private var watchdog: Timer?
    private var wakeObserver: NSObjectProtocol?

    // The link's thread uses these too.
    private let lock = NSLock()
    private var waiting = false
    private var minInterval = CoreVideoClock.idleInterval
    private var lastHanded: CFTimeInterval = 0

    init(onFrame: @escaping (CFTimeInterval) -> Void) {
        self.onFrame = onFrame
        makeLink()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in self?.check() }
        RunLoop.main.add(timer, forMode: .common)
        watchdog = timer
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.check()
        }
    }

    deinit {
        watchdog?.invalidate()
        if let wakeObserver { NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver) }
        if let link { CVDisplayLinkStop(link) }
    }

    var isPaused = true {
        didSet {
            guard isPaused != oldValue else { return }
            lastFrame = CACurrentMediaTime()
            check()
        }
    }

    var isLively = false {
        didSet {
            lock.lock()
            minInterval = isLively ? Self.livelyInterval : Self.idleInterval
            lock.unlock()
        }
    }

    func follow(_ screen: NSScreen?) {
        guard let id = screen?.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else { return }
        display = id
        // A link made before a display was plugged in can refuse to move to it.
        if let link, CVDisplayLinkSetCurrentCGDisplay(link, id) == kCVReturnSuccess { return }
        makeLink()
        check()
    }

    private var displaysAsleep: Bool {
        NSScreen.screens.allSatisfy {
            guard let id = $0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else { return false }
            return CGDisplayIsAsleep(id) != 0
        }
    }

    private func check() {
        if isPaused || displaysAsleep {
            if let link, CVDisplayLinkIsRunning(link) { CVDisplayLinkStop(link) }
            return
        }
        if link == nil || CACurrentMediaTime() - lastFrame > 1 { makeLink() }
        if let link, !CVDisplayLinkIsRunning(link) {
            lastFrame = CACurrentMediaTime()
            CVDisplayLinkStart(link)
        }
    }

    private func makeLink() {
        if let link { CVDisplayLinkStop(link) }
        link = nil
        // Not made from the active displays, because that fails while they're all asleep.
        var made: CVDisplayLink?
        guard CVDisplayLinkCreateWithCGDisplay(display, &made) == kCVReturnSuccess, let made else {
            display = CGMainDisplayID()
            return
        }
        CVDisplayLinkSetOutputHandler(made) { [weak self] _, now, _, _, _ in
            self?.tick(at: Double(now.pointee.hostTime) / CVGetHostClockFrequency())
            return kCVReturnSuccess
        }
        link = made
    }

    /// One frame at a time, so that a busy main thread doesn't build up a queue of them.
    private func tick(at now: CFTimeInterval) {
        lock.lock()
        let wanted = !waiting && now - lastHanded >= minInterval
        if wanted {
            waiting = true
            lastHanded = now
        }
        lock.unlock()
        guard wanted else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.lock.lock()
            self.waiting = false
            self.lock.unlock()
            self.lastFrame = CACurrentMediaTime()
            // This may have been on its way when the clock was paused.
            if !self.isPaused { self.onFrame(now) }
        }
    }
}
