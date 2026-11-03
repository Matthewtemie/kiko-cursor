import AppKit
import KikoCore

/// Works out which cursor the frontmost app has asked for. It still reports correctly
/// while the real pointer is hidden, which is what makes Kiko context-aware.
final class SystemCursorWatcher {
    private typealias Seed = @convention(c) () -> Int32

    private let seedFn: Seed?
    private var lastSeed: Int32 = -1
    private var lastFullRead: CFTimeInterval = 0
    private let arrow = SystemCursorWatcher.signature(.arrow)
    private let link = SystemCursorWatcher.signature(.pointingHand)
    private var lastSignature: CGRect = .null

    private(set) var kind = CursorKind.arrow
    private(set) var image: CursorImage?

    init() {
        seedFn = dlsym(dlopen(nil, RTLD_NOW), "CGSCurrentCursorSeed").map { unsafeBitCast($0, to: Seed.self) }
    }

    private static func signature(_ c: NSCursor) -> CGRect {
        CGRect(origin: c.hotSpot, size: c.image.size)
    }

    func update(now: CFTimeInterval) {
        // The seed is nanoseconds to read and reading the cursor is 200µs, so only read
        // on a change, plus a slow poll in case the seed ever stops moving.
        let seed = seedFn?() ?? -1
        guard seed != lastSeed || now - lastFullRead > 0.25 else { return }
        lastSeed = seed
        lastFullRead = now

        guard let cursor = NSCursor.currentSystem else { return }
        let sig = SystemCursorWatcher.signature(cursor)
        guard sig != lastSignature else { return }
        lastSignature = sig

        if sig == arrow {
            kind = .arrow
            image = nil
        } else if sig == link {
            kind = .link
            image = nil
        } else {
            kind = .other
            image = cursor.image.cgImage(forProposedRect: nil, context: nil, hints: nil).map {
                CursorImage(image: $0, size: cursor.image.size, hotSpot: cursor.hotSpot)
            }
        }
    }
}
