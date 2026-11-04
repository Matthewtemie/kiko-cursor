import AppKit
import KikoCore

private final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect { frameRect }
}

/// Draws into its own bitmap and hands that to a layer. AppKit's view drawing records and
/// replays a display list, which profiled at about four times the cost of the drawing itself.
private final class Canvas {
    let layer = CALayer()
    private var ctx: CGContext?
    private var pixels = 0
    private(set) var lastImage: CGImage?

    init() {
        layer.isOpaque = false
        layer.contentsGravity = .resize
        layer.actions = ["contents": NSNull(), "bounds": NSNull(), "position": NSNull()]
    }

    /// Draws in the display's own colour space. Given anything else, Core Animation converts
    /// the whole bitmap pixel by pixel on every commit, which profiled at about as much work
    /// as drawing the character. Kiko's colours are sRGB values, so they still come out right.
    func resize(side: CGFloat, pixelScale: CGFloat, colorSpace: CGColorSpace) {
        pixels = Int(side * pixelScale)
        ctx = CGContext(data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
                        space: colorSpace,
                        bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        layer.contentsScale = pixelScale
    }

    func render(_ pose: Pose, cursor: CursorImage?, scale: CGFloat, pixelScale: CGFloat) {
        guard let ctx else { return }
        ctx.saveGState()
        ctx.clear(CGRect(x: 0, y: 0, width: pixels, height: pixels))
        ctx.translateBy(x: CGFloat(pixels) / 2, y: CGFloat(pixels) / 2)
        ctx.scaleBy(x: pixelScale * scale, y: -pixelScale * scale)
        // The real cursor image keeps its native size whatever size Kiko is.
        let native = cursor.map {
            CursorImage(image: $0.image,
                        size: CGSize(width: $0.size.width / scale, height: $0.size.height / scale),
                        hotSpot: CGPoint(x: $0.hotSpot.x / scale, y: $0.hotSpot.y / scale))
        }
        AvatarRenderer.draw(pose, in: ctx, cursor: native)
        ctx.restoreGState()
        lastImage = ctx.makeImage()
        layer.contents = lastImage
    }
}

/// The click-through window that follows the mouse with Kiko in it. The hotspot stays
/// at the centre of the window, so the fingertip is exact whatever the drawing is doing.
final class Overlay: NSObject {
    private let window: OverlayWindow
    private let host = NSView()
    private let canvas = Canvas()
    private let rig = Rig()
    private let watcher = SystemCursorWatcher()
    let hider = CursorHider()

    private var clock: FrameClock?
    private var monitors: [Any] = []
    private var lastTick: CFTimeInterval = 0
    private var lastDraw: CFTimeInterval = 0
    private var lastFullscreenCheck: CFTimeInterval = 0
    private var runningLively = false
    private var fullscreenIdle = false
    private var halfSide: CGFloat = 0
    private var pixelScale: CGFloat = 0
    private var colorSpace: CGColorSpace?
    private var lastOrigin = NSPoint(x: CGFloat.nan, y: CGFloat.nan)
    private var currentScreen: NSScreen?
    private var active = false

    var avatar: Avatar {
        get { rig.avatar }
        set {
            rig.avatar = newValue
            lastDraw = 0
            // Switched off, nothing redraws, and the last character would flash up when it comes back.
            if !active { canvas.layer.contents = nil }
        }
    }

    var fadeWhileTyping = true
    var hideInFullscreen = true

    var scale: CGFloat = 0.85 {
        didSet { applyScale() }
    }

    var capturable = false {
        didSet { window.sharingType = capturable ? .readOnly : .none }
    }

    init(forceCoreVideoClock: Bool = false) {
        window = OverlayWindow(contentRect: NSRect(x: 0, y: 0, width: 200, height: 200),
                               styleMask: .borderless, backing: .buffered, defer: false)
        super.init()

        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.isReleasedWhenClosed = false
        window.animationBehavior = .none
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.cursorWindow)))
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        // Screenshots normally leave the pointer out, so they leave Kiko out too.
        window.sharingType = .none

        host.layer = canvas.layer
        host.wantsLayer = true
        window.contentView = host
        applyScale()

        clock = makeFrameClock(for: host, forceCoreVideo: forceCoreVideoClock) { [weak self] now in
            self?.tick(now: now)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(backingChanged),
                                               name: NSWindow.didChangeBackingPropertiesNotification, object: window)
    }

    func setActive(_ on: Bool) {
        guard on != active else { return }
        active = on
        hider.wantsHidden = on
        if on {
            place(at: NSEvent.mouseLocation)
            window.orderFrontRegardless()
            addMonitors()
            lastTick = 0
            clock?.isPaused = false
        } else {
            clock?.isPaused = true
            removeMonitors()
            window.orderOut(nil)
        }
    }

    /// After sleep, a display change or anything else that might have reset the pointer.
    func reassert() {
        hider.apply()
        // Also moves the clock off a display that may have just gone away, which it can't do from
        // a frame, because a clock on a missing display has no frames.
        currentScreen = nil
        _ = screenUnder(NSEvent.mouseLocation)
        syncPixelScale()
        if active {
            window.orderFrontRegardless()
        }
    }

    /// Writes the bitmap the layer is showing to a PNG. A test hook: it needs no Screen
    /// Recording permission.
    func dumpFrame(to url: URL) {
        guard let image = canvas.lastImage else { return }
        try? NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])?.write(to: url)
    }

    private func applyScale() {
        halfSide = ceil(Rig.halfExtent * scale)
        window.setContentSize(NSSize(width: halfSide * 2, height: halfSide * 2))
        host.frame = NSRect(x: 0, y: 0, width: halfSide * 2, height: halfSide * 2)
        canvas.layer.frame = host.bounds
        pixelScale = window.backingScaleFactor
        colorSpace = window.colorSpace?.cgColorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!
        canvas.resize(side: halfSide * 2, pixelScale: pixelScale, colorSpace: colorSpace!)
        lastOrigin = NSPoint(x: CGFloat.nan, y: CGFloat.nan)
        lastDraw = 0
        place(at: NSEvent.mouseLocation)
    }

    /// Moving to a display with a different scale or colour space changes the bitmap Kiko needs.
    private func syncPixelScale() {
        if window.backingScaleFactor != pixelScale || window.colorSpace?.cgColorSpace != colorSpace {
            applyScale()
        }
    }

    /// The check when the pointer crosses to another display can run before the window has moved.
    @objc private func backingChanged() {
        syncPixelScale()
    }

    private func place(at mouse: NSPoint) {
        let origin = NSPoint(x: ((mouse.x - halfSide) * pixelScale).rounded() / pixelScale,
                             y: ((mouse.y - halfSide) * pixelScale).rounded() / pixelScale)
        guard origin != lastOrigin else { return }
        lastOrigin = origin
        window.setFrameOrigin(origin)
    }

    private func addMonitors() {
        let moves: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]
        // Follow straight away rather than waiting for the next frame: this is what keeps
        // the pointer feeling attached to the hand.
        if let global = NSEvent.addGlobalMonitorForEvents(matching: moves, handler: { [weak self] _ in
            self?.mouseMoved()
        }) {
            monitors.append(global)
        }
        if let local = NSEvent.addLocalMonitorForEvents(matching: moves, handler: { [weak self] event in
            self?.mouseMoved()
            return event
        }) {
            monitors.append(local)
        }
    }

    private func removeMonitors() {
        monitors.forEach(NSEvent.removeMonitor)
        monitors.removeAll()
    }

    private func mouseMoved() {
        place(at: NSEvent.mouseLocation)
        setRate(lively: true)
    }

    private func setRate(lively: Bool) {
        guard lively != runningLively else { return }
        runningLively = lively
        clock?.isLively = lively
    }

    private func screenUnder(_ mouse: NSPoint) -> NSScreen? {
        if let currentScreen, currentScreen.frame.contains(mouse) {
            return currentScreen
        }
        currentScreen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
        clock?.follow(currentScreen)
        syncPixelScale()
        return currentScreen
    }

    private func tick(now: CFTimeInterval) {
        let dt = lastTick == 0 ? 1.0 / 60 : now - lastTick
        lastTick = now

        let mouse = NSEvent.mouseLocation
        let screen = screenUnder(mouse)
        place(at: mouse)
        watcher.update(now: now)

        hider.apply()

        var screenRect = CGRect(x: -10000, y: -10000, width: 20000, height: 20000)
        if let f = screen?.frame {
            screenRect = CGRect(x: f.minX, y: -f.maxY, width: f.width, height: f.height)
        }

        let keyAge = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .keyDown)
        let mouseAge = min(CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .mouseMoved),
                           CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .leftMouseDragged))

        updateFullscreenIdle(now: now, screen: screen)

        let pose = rig.step(RigInput(dt: dt,
                                     mouse: CGPoint(x: mouse.x, y: -mouse.y),
                                     buttons: NSEvent.pressedMouseButtons,
                                     kind: watcher.kind,
                                     screen: screenRect,
                                     typing: fadeWhileTyping && keyAge < mouseAge,
                                     hiddenWhenIdle: fullscreenIdle))

        // When the system insists on showing the real pointer, it gets to be the only one.
        let opacity = hider.isForcedVisible ? 0 : pose.opacity
        if abs(window.alphaValue - opacity) > 0.004 {
            window.alphaValue = opacity
        }

        let lively = rig.isLively
        setRate(lively: lively)

        guard opacity > 0.01 else { return }

        // The window itself tracks the mouse at the full display rate. The drawing inside it
        // only needs to look alive, and the rate drops the longer Kiko has been still:
        // 60 fps moving, then 30, 10 and 7.5 (every 1st, 3rd and 4th tick of the 30 Hz idle
        // rate). Measured at about 10.5%, 3% and 1-2.6% of one core.
        let interval: Double
        if lively {
            interval = 1.0 / 62
        } else if rig.idleSeconds > 25 {
            interval = 1.0 / 7.6
        } else if rig.idleSeconds > 1.5 {
            interval = 1.0 / 10.5
        } else {
            interval = 1.0 / 31
        }
        if now - lastDraw >= interval {
            lastDraw = now
            canvas.render(pose, cursor: watcher.kind == .other ? watcher.image : nil, scale: scale, pixelScale: pixelScale)
        }
    }

    private func updateFullscreenIdle(now: CFTimeInterval, screen: NSScreen?) {
        guard hideInFullscreen, rig.idleSeconds > 2, let screen else {
            fullscreenIdle = false
            return
        }
        // Reading the window list takes milliseconds, so only look now and again.
        if now - lastFullscreenCheck > 3 {
            lastFullscreenCheck = now
            fullscreenIdle = frontmostCovers(screen)
        }
    }

    private func frontmostCovers(_ screen: NSScreen) -> Bool {
        guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier,
              let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]]
        else { return false }
        for w in windows {
            guard (w[kCGWindowOwnerPID as String] as? pid_t) == pid,
                  (w[kCGWindowLayer as String] as? Int) == 0,
                  let bounds = w[kCGWindowBounds as String] as? NSDictionary,
                  let rect = CGRect(dictionaryRepresentation: bounds)
            else { continue }
            if rect.width >= screen.frame.width && rect.height >= screen.frame.height {
                return true
            }
        }
        return false
    }
}
