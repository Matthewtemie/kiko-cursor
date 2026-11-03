import AppKit

/// Hides the real pointer while Kiko is out.
///
/// CGDisplayHideCursor only works for the frontmost app unless the connection has the
/// private "SetsCursorInBackground" property, so that is looked up at runtime: if a
/// future macOS removes it the app shows both pointers rather than crashing. The hidden
/// state belongs to this process, so WindowServer restores the pointer the moment the
/// app exits, even after a crash.
final class CursorHider {
    private typealias MainConnection = @convention(c) () -> Int32
    private typealias SetProperty = @convention(c) (Int32, Int32, CFString, CFTypeRef) -> Int32
    private typealias IsVisible = @convention(c) () -> Int32

    private let isVisibleFn: IsVisible?
    private var hideCount = 0
    private var visibleSince: CFTimeInterval?
    private var lastAttempt: CFTimeInterval = 0

    let canHideInBackground: Bool
    var wantsHidden = false {
        didSet { apply() }
    }

    init() {
        let handle = dlopen(nil, RTLD_NOW)
        isVisibleFn = dlsym(handle, "CGCursorIsVisible").map { unsafeBitCast($0, to: IsVisible.self) }

        if let connSym = dlsym(handle, "_CGSDefaultConnection"),
           let setSym = dlsym(handle, "CGSSetConnectionProperty") {
            let conn = unsafeBitCast(connSym, to: MainConnection.self)()
            let set = unsafeBitCast(setSym, to: SetProperty.self)
            canHideInBackground = set(conn, conn, "SetsCursorInBackground" as CFString, kCFBooleanTrue) == 0
        } else {
            canHideInBackground = false
        }
    }

    var isCursorVisible: Bool {
        isVisibleFn.map { $0() != 0 } ?? (hideCount == 0)
    }

    /// True when the system is keeping the real pointer on and hiding it isn't working, as it
    /// does throughout Mission Control. A normal return is gone in milliseconds, so this only
    /// trips when it isn't going away. Kiko steps aside then, so there's only ever one pointer.
    var isForcedVisible: Bool {
        guard canHideInBackground, let visibleSince else { return false }
        return CACurrentMediaTime() - visibleSince > 0.25
    }

    /// Test hook: brings the pointer back the way the system can, without updating any state
    /// here, so only the re-hide check can put it right.
    func simulateSystemReset() {
        CGDisplayShowCursor(CGMainDisplayID())
    }

    /// Switching apps and reaching the menu bar bring the pointer back, so this runs every
    /// frame as well. The check costs under a microsecond.
    func apply() {
        guard wantsHidden else {
            visibleSince = nil
            showAll()
            return
        }
        guard isCursorVisible else {
            visibleSince = nil
            return
        }
        let now = CACurrentMediaTime()
        if visibleSince == nil {
            visibleSince = now
        }
        guard now - lastAttempt > 0.1 else { return }
        lastAttempt = now

        // From zero each time, so the count can't climb with every return.
        showAll()
        CGDisplayHideCursor(CGMainDisplayID())
        hideCount = 1
    }

    private func showAll() {
        while hideCount > 0 {
            CGDisplayShowCursor(CGMainDisplayID())
            hideCount -= 1
        }
    }
}
