import AppKit
import KikoCore

/// Logic checks that drive the Rig with scripted input. Run with `KikoCursor --check`.
/// They live in the app because the Command Line Tools ship no test framework.
enum Checks {
    private static let screen = CGRect(x: 0, y: 0, width: 1512, height: 982)
    private static let dt = 1.0 / 60
    private static var failures = 0

    private static func expect(_ ok: Bool, _ name: String, _ detail: @autoclosure () -> String = "") {
        print(ok ? "  ok    \(name)" : "  FAIL  \(name) \(detail())")
        if !ok { failures += 1 }
    }

    private static func hold(_ rig: Rig, _ p: CGPoint, _ seconds: Double, buttons: Int = 0, kind: CursorKind = .arrow,
                             typing: Bool = false, hide: Bool = false) -> Pose {
        var pose = Pose()
        for _ in 0..<Int(seconds / dt) {
            pose = rig.step(RigInput(dt: dt, mouse: p, buttons: buttons, kind: kind, screen: screen, typing: typing, hiddenWhenIdle: hide))
        }
        return pose
    }

    /// Everything Kiko draws must fit in the window, or it gets clipped.
    private static func extent(_ pose: Pose) -> CGFloat {
        var far = hypot(pose.body.x, pose.body.y) + 46
        for p in pose.scarfA + pose.scarfB { far = max(far, max(abs(p.x), abs(p.y))) }
        return far
    }

    /// A bitmap with room well beyond the window, one pixel to the point, origin at its centre.
    private static let inkSide = 320
    private static func inkCanvas() -> CGContext {
        let ctx = CGContext(data: nil, width: inkSide, height: inkSide, bitsPerComponent: 8, bytesPerRow: inkSide * 4,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.translateBy(x: CGFloat(inkSide) / 2, y: CGFloat(inkSide) / 2)
        ctx.scaleBy(x: 1, y: -1)
        return ctx
    }

    private static func render(_ pose: Pose, _ ctx: CGContext) {
        memset(ctx.data!, 0, inkSide * inkSide * 4)
        AvatarRenderer.draw(pose, in: ctx)
    }

    /// How far from the hotspot any ink lands, along either axis. The window is square and
    /// centred, so this is what decides whether it fits. Only looks past 90 points, for speed.
    private static func farthestInk(_ ctx: CGContext) -> Int {
        let bytes = ctx.data!.assumingMemoryBound(to: UInt8.self)
        let half = inkSide / 2
        var far = 0
        // To the far edge of each pixel: the first pixel past the centre already reaches 1.
        func out(_ v: Int) -> Int { v < half ? half - v : v + 1 - half }
        for y in 0..<inkSide {
            let dy = out(y)
            for x in 0..<inkSide {
                let reach = max(dy, out(x))
                if reach > 90, reach > far, bytes[(y * inkSide + x) * 4 + 3] > 8 { far = reach }
            }
        }
        return far
    }

    /// What's within `radius` of the hotspot, as raw bytes to compare.
    private static func hotspotPixels(_ ctx: CGContext, radius: Int) -> [UInt8] {
        let bytes = ctx.data!.assumingMemoryBound(to: UInt8.self)
        let half = inkSide / 2
        var out: [UInt8] = []
        for y in (half - radius)...(half + radius) {
            for x in (half - radius)...(half + radius) {
                let i = (y * inkSide + x) * 4
                out += [bytes[i], bytes[i + 1], bytes[i + 2], bytes[i + 3]]
            }
        }
        return out
    }

    private static func pixel(_ ctx: CGContext, at p: CGPoint) -> [UInt8] {
        let bytes = ctx.data!.assumingMemoryBound(to: UInt8.self)
        let i = (Int((CGFloat(inkSide / 2) + p.y).rounded(.down)) * inkSide + Int((CGFloat(inkSide / 2) + p.x).rounded(.down))) * 4
        return [bytes[i], bytes[i + 1], bytes[i + 2], bytes[i + 3]]
    }

    private static func hotspotAlpha(_ ctx: CGContext) -> UInt8 {
        let bytes = ctx.data!.assumingMemoryBound(to: UInt8.self)
        return bytes[(inkSide / 2 * inkSide + inkSide / 2) * 4 + 3]
    }

    private static func differingPixels(_ a: [UInt8], _ b: [UInt8]) -> Int {
        var n = 0
        for i in stride(from: 0, to: min(a.count, b.count), by: 4)
        where abs(Int(a[i]) - Int(b[i])) + abs(Int(a[i + 1]) - Int(b[i + 1])) + abs(Int(a[i + 2]) - Int(b[i + 2])) + abs(Int(a[i + 3]) - Int(b[i + 3])) > 24 {
            n += 1
        }
        return n
    }

    private static func allPixels(_ ctx: CGContext) -> [UInt8] {
        Array(UnsafeBufferPointer(start: ctx.data!.assumingMemoryBound(to: UInt8.self), count: inkSide * inkSide * 4))
    }

    /// Every avatar on hostile paths: flat out in each direction, with clicks, links and a text
    /// cursor, and at the screen edges. Returns the farthest any ink got from the hotspot.
    private static func inkReach(_ avatar: Avatar) -> Int {
        let ctx = inkCanvas()
        var far = 0
        let paths: [(Double) -> CGPoint] = [
            { CGPoint(x: 756 + 650 * sin($0 * 5.3), y: 491 + 400 * sin($0 * 7.9)) },
            { CGPoint(x: 700, y: 491 + 460 * sin($0 * 9.1)) },
            { CGPoint(x: 756 + 720 * sin($0 * 9.7), y: 480) },
            { CGPoint(x: 4 + 3 * sin($0), y: 975 - 970 * abs(sin($0 * 3.7))) },
            { CGPoint(x: 1508 - 1500 * abs(sin($0 * 2.9)), y: 4 + 3 * sin($0)) },
        ]
        for path in paths {
            for textCursor in [false, true] {
                let rig = Rig(avatar: avatar)
                for i in 0..<360 {
                    let t = Double(i) * dt
                    let kind: CursorKind = textCursor ? .other : (i % 120 < 50 ? .link : .arrow)
                    render(rig.step(RigInput(dt: dt, mouse: path(t), buttons: i % 40 < 6 ? 1 : 0, kind: kind, screen: screen)), ctx)
                    far = max(far, farthestInk(ctx))
                }
            }
        }
        return far
    }

    static func run() -> Bool {
        failures = 0

        for avatar in Avatar.allCases {
            runSharedChecks(avatar)
        }
        runAvatarChecks()
        runClockChecks()

        print(failures == 0 ? "all checks passed" : "\(failures) check(s) FAILED")
        return failures == 0
    }

    /// What must hold whoever is on screen.
    private static func runSharedChecks(_ avatar: Avatar) {
        let centre = CGPoint(x: 700, y: 480)
        func Rig() -> KikoCore.Rig { KikoCore.Rig(avatar: avatar) }
        print("\(avatar.name): pointer accuracy")
        do {
            let rig = Rig()
            var worst: CGFloat = 0
            var pose = hold(rig, centre, 0.5)
            worst = max(worst, hypot(pose.fingerTip.x, pose.fingerTip.y))
            // Random-looking path at high speed: the fingertip must never leave the hotspot.
            for i in 0..<600 {
                let t = Double(i) * dt
                let p = CGPoint(x: 700 + 500 * sin(t * 3.1), y: 480 + 300 * sin(t * 4.7))
                pose = rig.step(RigInput(dt: dt, mouse: p, screen: screen))
                worst = max(worst, hypot(pose.fingerTip.x, pose.fingerTip.y))
            }
            expect(worst == 0, "fingertip stays exactly on the hotspot while moving", "off by \(worst)")
            let link = hold(Rig(), centre, 1, kind: .link)
            expect(link.fingerTip == .zero, "fingertip is the pointer over links too")
            let text = hold(Rig(), centre, 1, kind: .other)
            expect(hypot(text.fingerTip.x, text.fingerTip.y) > 20, "finger gets out of the way of a text cursor")
        }

        print("\(avatar.name): leash and window")
        do {
            let rig = Rig()
            var minD = CGFloat.infinity, maxD: CGFloat = 0, maxExtent: CGFloat = 0
            for i in 0..<1200 {
                let t = Double(i) * dt
                let p = CGPoint(x: 756 + 650 * sin(t * 5.3), y: 491 + 400 * sin(t * 7.9))
                let pose = rig.step(RigInput(dt: dt, mouse: p, screen: screen))
                if i > 10 {
                    let d = hypot(pose.body.x, pose.body.y)
                    minD = min(minD, d)
                    maxD = max(maxD, d)
                    maxExtent = max(maxExtent, extent(pose))
                }
            }
            expect(minD >= KikoCore.Rig.minBodyDistance - 0.5, "body never sits on the pointer", "min \(minD)")
            expect(maxD <= KikoCore.Rig.maxBodyDistance + 0.5, "arm never over-stretches", "max \(maxD)")
            expect(maxExtent <= KikoCore.Rig.halfExtent, "every pose fits the window", "extent \(maxExtent)")
            let reach = inkReach(avatar)
            print("        ink reaches \(reach) of \(Int(KikoCore.Rig.halfExtent)) points")
            expect(CGFloat(reach) <= KikoCore.Rig.halfExtent, "no ink ever lands outside the window", "reaches \(reach)")
        }

        print("\(avatar.name): screen edges")
        do {
            let right = hold(Rig(), CGPoint(x: screen.maxX - 5, y: 400), 1)
            expect(right.body.x < 0, "body moves left of the pointer at the right edge", "\(right.body)")
            expect(right.facing < 0, "and turns to face it", "\(right.facing)")
            let bottom = hold(Rig(), CGPoint(x: 600, y: screen.maxY - 5), 1)
            expect(bottom.body.y < 0, "body moves above the pointer at the bottom edge", "\(bottom.body)")
            let top = hold(Rig(), CGPoint(x: 600, y: screen.minY + 1), 1)
            expect(top.body.y > 32, "body hangs lower at the top edge", "\(top.body)")
            let left = hold(Rig(), CGPoint(x: screen.minX + 2, y: 400), 1)
            expect(left.body.x > 0, "body stays right of the pointer at the left edge", "\(left.body)")

            // And it has to come back: the edges above each started from a fresh rig.
            let rightThenLeft = Rig()
            _ = hold(rightThenLeft, CGPoint(x: screen.maxX - 5, y: 400), 1)
            let atLeft = hold(rightThenLeft, CGPoint(x: screen.minX + 2, y: 400), 1)
            expect(atLeft.body.x > 0, "right edge to left edge puts the body back on the right", "\(atLeft.body)")
            let rightThenMiddle = Rig()
            _ = hold(rightThenMiddle, CGPoint(x: screen.maxX - 5, y: 400), 1)
            let fromRight = hold(rightThenMiddle, centre, 1)
            expect(fromRight.body.x > 0, "and so does coming back to the middle", "\(fromRight.body)")
            let bottomThenMiddle = Rig()
            _ = hold(bottomThenMiddle, CGPoint(x: 600, y: screen.maxY - 5), 1)
            let fromBottom = hold(bottomThenMiddle, centre, 1)
            expect(fromBottom.body.y > 0, "and below the pointer again after the bottom edge", "\(fromBottom.body)")

            // Sliding along the edge must not make Kiko flip back and forth.
            let rig = Rig()
            var flips = 0
            var last: CGFloat?
            for i in 0..<300 {
                let x = screen.maxX - 95 + 4 * sin(Double(i) * 0.3)
                let s = rig.step(RigInput(dt: dt, mouse: CGPoint(x: x, y: 400), screen: screen)).body.x < 0 ? CGFloat(-1) : 1
                if i > 30, let last, last != s { flips += 1 }
                last = s
            }
            expect(flips == 0, "no flip-flopping along an edge", "\(flips) flips")
        }

        print("\(avatar.name): reactions")
        do {
            let rig = Rig()
            _ = hold(rig, centre, 0.3)
            expect(hold(rig, centre, 0.05, buttons: 1).expression == .happy, "click makes Kiko happy")
            let burst = hold(rig, centre, 0.03, buttons: 1)
            expect(!burst.sparkles.isEmpty, "click throws sparkles")
            expect(hold(rig, centre, 0.8, buttons: 1).expression == .focused, "holding the button looks focused")
            expect(hold(rig, centre, 0.5).expression == .neutral, "back to neutral on release")
            expect(hold(rig, centre, 0.5).sparkles.isEmpty, "sparkles finish")

            let sleepy = Rig()
            _ = hold(sleepy, centre, 24)
            expect(sleepy.expression != .asleep, "awake before 25s idle")
            let asleep = hold(sleepy, centre, 3)
            expect(asleep.expression == .asleep, "asleep after 25s idle")
            expect(!asleep.zees.isEmpty, "with Zs")
            var woke = Pose()
            for i in 0..<10 {
                woke = sleepy.step(RigInput(dt: dt, mouse: CGPoint(x: centre.x + CGFloat(i) * 8, y: centre.y), screen: screen))
            }
            expect(woke.expression != .asleep, "moving the mouse wakes Kiko")

            let shaken = Rig()
            _ = hold(shaken, centre, 0.2)
            var x = centre.x, dir: CGFloat = 1
            var dizzy = false
            for i in 0..<80 {
                if i % 8 == 0 { dir = -dir }
                x += dir * 36
                if shaken.step(RigInput(dt: dt, mouse: CGPoint(x: x, y: 480), screen: screen)).expression == .dizzy { dizzy = true }
            }
            expect(dizzy, "shaking the mouse makes Kiko dizzy")

            let steady = Rig()
            var everDizzy = false
            for i in 0..<300 {
                let p = CGPoint(x: 200 + CGFloat(i) * 3, y: 400 + 40 * sin(CGFloat(i) * 0.02))
                if steady.step(RigInput(dt: dt, mouse: p, screen: screen)).expression == .dizzy { everDizzy = true }
            }
            expect(!everDizzy, "ordinary movement does not")

            let turnedOnce = Rig()
            _ = hold(turnedOnce, centre, 0.2)
            var turnedDizzy = false
            for i in 0..<60 {
                let p = CGPoint(x: centre.x + 20 * CGFloat(i < 30 ? i : 60 - i), y: 480)
                if turnedOnce.step(RigInput(dt: dt, mouse: p, screen: screen)).expression == .dizzy { turnedDizzy = true }
            }
            expect(!turnedDizzy, "nor does turning back once at speed")

            expect(hold(Rig(), centre, 1, kind: .link).expression == .excited, "links make Kiko excited")
        }

        print("\(avatar.name): getting out of the way")
        do {
            let rig = Rig()
            _ = hold(rig, centre, 0.5)
            let typing = hold(rig, centre, 1, typing: true)
            expect(abs(typing.opacity - 0.25) < 0.02, "fades while typing", "\(typing.opacity)")
            let back = hold(rig, centre, 0.4)
            expect(back.opacity > 0.97, "returns when typing stops", "\(back.opacity)")

            let video = Rig()
            let early = hold(video, centre, 1, hide: true)
            expect(early.opacity > 0.97, "still visible for the first moments in full screen", "\(early.opacity)")
            let gone = hold(video, centre, 3, hide: true)
            expect(gone.opacity < 0.01, "gone when idle in full screen", "\(gone.opacity)")
            var returning = Pose()
            for i in 0..<12 {
                returning = video.step(RigInput(dt: dt, mouse: CGPoint(x: centre.x + CGFloat(i) * 8, y: centre.y), screen: screen, hiddenWhenIdle: true))
            }
            expect(returning.opacity > 0.9, "back at once when the mouse moves", "\(returning.opacity)")
        }

        print("\(avatar.name): stability")
        do {
            let rig = Rig()
            // Long frames (a stalled main thread) and a jump across displays must not explode.
            var pose = hold(rig, centre, 0.5)
            for _ in 0..<20 { pose = rig.step(RigInput(dt: 0.5, mouse: centre, screen: screen)) }
            expect(abs(pose.headTilt) < 1 && abs(pose.tailAngle) < 3 && abs(pose.lean) < 1 && abs(pose.earL) < 2,
                   "survives stalls", "tilt \(pose.headTilt) tail \(pose.tailAngle) lean \(pose.lean) ear \(pose.earL)")
            pose = rig.step(RigInput(dt: dt, mouse: CGPoint(x: 4000, y: 2000), screen: CGRect(x: 3000, y: 1000, width: 2000, height: 1500)))
            expect(hypot(pose.body.x - 36, pose.body.y - 32) < 1, "a jump between displays starts it afresh", "\(pose.body)")
            expect(pose.scarfA.allSatisfy { $0.x.isFinite && abs($0.x) < 120 }, "scarf stays attached after a jump")

            // A slow display, or a slow Mac, ticks this rarely. A single turn must not set the
            // stiffer springs off.
            let slow = Rig()
            var wildest: CGFloat = 0
            for i in 0..<480 {
                let p = CGPoint(x: centre.x + 40 * CGFloat(min(i, 12)), y: centre.y)
                let f = slow.step(RigInput(dt: 1.0 / 24, mouse: p, screen: screen)).facing
                wildest = max(wildest, f.isFinite ? abs(f) : .infinity)
            }
            expect(wildest < 1.5, "turning at 24 frames a second stays in hand", "facing reached \(wildest)")

            // With nothing moving the display link slows right down, or it costs battery all day.
            func framesLively(_ rig: KikoCore.Rig) -> Int {
                var n = 0
                for _ in 0..<600 {
                    _ = rig.step(RigInput(dt: dt, mouse: centre, screen: screen))
                    if rig.isLively { n += 1 }
                }
                return n
            }
            let calm = Rig()
            _ = hold(calm, centre, 2)
            let awake = framesLively(calm)
            expect(awake == 0, "settles to the idle rate when nothing is moving", "\(awake) of 600 frames lively")
            _ = hold(calm, centre, 20)
            let dozing = framesLively(calm)
            expect(calm.expression == .asleep && dozing == 0, "and asleep", "\(dozing) of 600 frames lively")
        }

        print("\(avatar.name): poses")
        do {
            let rig = Rig()
            expect(hold(rig, centre, 0.5).avatar == avatar, "the pose says who it's for")
            expect(hold(rig, centre, 1, kind: .link).hover > 0.8, "hover comes up over a link")
            expect(hold(rig, centre, 1).hover < 0.05, "and goes back down")
            let sleepy = Rig()
            expect(hold(sleepy, centre, 24.5).drowse == 0, "not drowsy while awake")
            expect(hold(sleepy, centre, 4).drowse > 0.8, "drowsy once asleep")
            var woke = Pose()
            for i in 0..<90 {
                woke = sleepy.step(RigInput(dt: dt, mouse: CGPoint(x: centre.x + CGFloat(i) * 3, y: centre.y), screen: screen))
            }
            expect(woke.drowse < 0.1, "wide awake again after moving", "\(woke.drowse)")

            // The finger has to be there.
            let ctx = inkCanvas()
            let still = hold(Rig(), centre, 1)
            render(still, ctx)
            expect(hotspotAlpha(ctx) > 200, "the fingertip is drawn on the hotspot", "alpha \(hotspotAlpha(ctx))")

            // Compared with the same arm with the body shrunk away, nothing about the body may
            // change what the finger looks like, wherever the body is around the pointer. This
            // is drawn zoomed in, so that the sample lands well inside the finger.
            let zoom: CGFloat = 6
            let lens = CGContext(data: nil, width: 120, height: 120, bitsPerComponent: 8, bytesPerRow: 480,
                                 space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                 bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            lens.translateBy(x: 60, y: 60)
            lens.scaleBy(x: zoom, y: -zoom)
            func sampleFinger(_ pose: Pose, _ at: CGPoint) -> [UInt8] {
                memset(lens.data!, 0, 120 * 120 * 4)
                AvatarRenderer.draw(pose, in: lens)
                let bytes = lens.data!.assumingMemoryBound(to: UInt8.self)
                let i = (Int(60 + at.y * zoom) * 120 + Int(60 + at.x * zoom)) * 4
                return [bytes[i], bytes[i + 1], bytes[i + 2], bytes[i + 3]]
            }
            // Three points along from the fingertip, towards the shoulder.
            func alongFinger(_ pose: Pose) -> CGPoint {
                let lx: CGFloat = pose.facing < 0 ? 7.8 : -7.8, ly: CGFloat = 3.5
                let c = cos(pose.lean), s = sin(pose.lean)
                let x = pose.body.x + lx * c - ly * s, y = pose.body.y + pose.bob + lx * s + ly * c
                let d = max(hypot(x, y), 0.01)
                return CGPoint(x: x / d * 3, y: y / d * 3)
            }
            var hidden = 0, placements = 0
            for i in 0..<24 {
                let a = CGFloat(i) / 24 * .pi * 2
                for distance in [KikoCore.Rig.minBodyDistance, 30, 36, 42, 48, 54, KikoCore.Rig.maxBodyDistance] {
                    for lean: CGFloat in [-0.3, 0, 0.3] {
                        var pose = still
                        pose.lean = lean
                        pose.body = CGPoint(x: cos(a) * distance, y: sin(a) * distance)
                        let dx = pose.body.x - still.body.x, dy = pose.body.y - still.body.y
                        pose.scarfA = still.scarfA.map { CGPoint(x: $0.x + dx, y: $0.y + dy) }
                        pose.scarfB = still.scarfB.map { CGPoint(x: $0.x + dx, y: $0.y + dy) }
                        let sample = alongFinger(pose)
                        let shown = sampleFinger(pose, sample)
                        pose.vanish = 1
                        pose.scarfA = []
                        pose.scarfB = []
                        placements += 1
                        if shown != sampleFinger(pose, sample) {
                            hidden += 1
                            print("        finger differs: body \(pose.body), lean \(lean), \(shown)")
                        }
                    }
                }
            }
            expect(hidden == 0, "the body never hides the finger", "\(hidden) of \(placements) placements")

            // Nor does anything a click throws out land on it.
            let flying = Rig()
            _ = hold(flying, centre, 1)
            var covered = 0
            for frame in 0..<40 {
                var pose = flying.step(RigInput(dt: dt, mouse: centre, buttons: frame < 6 ? 1 : 0, screen: screen))
                let sample = alongFinger(pose)
                let shown = sampleFinger(pose, sample)
                pose.sparkles = []
                pose.puffs = []
                if shown != sampleFinger(pose, sample) { covered += 1 }
            }
            expect(covered == 0, "and what a click throws out stays off it", "\(covered) of 40 frames")
        }
    }

    /// macOS 13's frame clock, which this runs whatever the system. It needs a display that's awake.
    private static func runClockChecks() {
        print("macOS 13's frame clock")
        guard CGDisplayIsAsleep(CGMainDisplayID()) == 0 else {
            print("  skipped: the display is asleep")
            return
        }
        var frames: [CFTimeInterval] = []
        let clock = makeFrameClock(for: NSView(), forceCoreVideo: true) { frames.append($0) }
        func count(over seconds: Double) -> Int {
            frames.removeAll()
            RunLoop.main.run(until: Date().addingTimeInterval(seconds))
            return frames.count
        }
        expect(count(over: 0.2) == 0, "no frames until it's started")
        clock.isPaused = false
        let idle = count(over: 1)
        expect((15...35).contains(idle), "about 30 frames a second while idle", "\(idle)")
        expect(zip(frames, frames.dropFirst()).allSatisfy { $0 < $1 }, "and always forwards")
        clock.isLively = true
        let lively = count(over: 1)
        expect(lively >= 45, "at least 45 a second while lively", "\(lively)")
        clock.isPaused = true
        expect(count(over: 0.2) == 0, "none once paused, not even one on its way")
        clock.isPaused = false
        expect(count(over: 0.3) > 0, "and they start again")
        clock.isPaused = true
    }

    /// What makes each character behave differently, and swapping between them.
    private static func runAvatarChecks() {
        let centre = CGPoint(x: 700, y: 480)

        print("Suzu: the puff of smoke")
        do {
            let rig = Rig(avatar: .suzu)
            _ = hold(rig, centre, 0.5)
            let during = hold(rig, centre, 0.1, buttons: 1)
            expect(during.vanish == 1, "a click hides her", "\(during.vanish)")
            expect(!during.puffs.isEmpty, "in smoke")
            expect(!during.sparkles.isEmpty, "while the shuriken fly")
            let held = hold(rig, centre, 0.5, buttons: 1)
            expect(held.vanish == 0, "she's back within half a second, even with the button held", "\(held.vanish)")
            expect(hold(rig, centre, 0.5).puffs.isEmpty, "the smoke clears")

            // A double click, at every gap that lands while she's coming back.
            var worstDrop: CGFloat = 0
            for gapFrames in 3..<30 {
                let twice = Rig(avatar: .suzu)
                _ = hold(twice, centre, 0.3)
                _ = hold(twice, centre, 0.05, buttons: 1)
                let beforeClick = hold(twice, centre, Double(gapFrames) * dt).vanish
                // The click's own frame is at most one ordinary step of her coming back, about 0.14.
                // From there she can only go further into the smoke.
                var last = twice.step(RigInput(dt: dt, mouse: centre, buttons: 1, screen: screen)).vanish
                worstDrop = max(worstDrop, beforeClick - last - 0.15)
                for frame in 0..<4 {
                    let now = twice.step(RigInput(dt: dt, mouse: centre, buttons: frame < 2 ? 1 : 0, screen: screen)).vanish
                    worstDrop = max(worstDrop, last - now)
                    last = now
                }
                expect(last == 1, "a second click after \(gapFrames) frames hides her again", "\(last)")
            }
            expect(worstDrop < 0.001, "and never brings her out early", "drops \(worstDrop)")

            // Smoke over a body right beside the pointer must still leave the fingertip showing.
            let ctx = inkCanvas()
            var close = during
            close.body = CGPoint(x: 18, y: 16)
            close.sparkles = []
            close.puffs = (0..<9).map { Puff(pos: CGPoint(x: 6 * cos(CGFloat($0)), y: 6 * sin(CGFloat($0))), radius: 16, alpha: 1) }
            render(close, ctx)
            let withSmoke = hotspotPixels(ctx, radius: 2)
            close.puffs = []
            render(close, ctx)
            let without = hotspotPixels(ctx, radius: 2)
            expect(withSmoke == without, "smoke never covers the fingertip", "\(differingPixels(withSmoke, without)) px differ")
        }

        print("Marlo: coins and waves")
        do {
            let rig = Rig(avatar: .marlo)
            _ = hold(rig, centre, 0.5)
            let early = hold(rig, centre, 0.1, buttons: 1)
            let late = hold(rig, centre, 0.32)
            func meanY(_ p: Pose) -> CGFloat { p.sparkles.map(\.pos.y).reduce(0, +) / CGFloat(max(p.sparkles.count, 1)) }
            expect(!early.sparkles.isEmpty && early.sparkles.count == late.sparkles.count, "a click throws coins, and they last")
            expect(meanY(early) < 0, "up first", "\(meanY(early))")
            expect(meanY(late) > meanY(early), "then falling", "\(meanY(early)) to \(meanY(late))")
            expect(hold(rig, centre, 0.5).sparkles.isEmpty, "and gone")

            func range(_ avatar: Avatar, _ value: (Pose) -> CGFloat) -> CGFloat {
                let r = Rig(avatar: avatar)
                _ = hold(r, centre, 0.5)
                var lo = CGFloat.infinity, hi = -CGFloat.infinity
                for _ in 0..<480 {
                    let v = value(r.step(RigInput(dt: dt, mouse: centre, screen: screen)))
                    lo = min(lo, v); hi = max(hi, v)
                }
                return hi - lo
            }
            let marloBob = range(.marlo) { $0.bob }, kikoBob = range(.kiko) { $0.bob }
            expect(marloBob > kikoBob * 3, "bobs far more than Kiko", "\(marloBob) against \(kikoBob)")
            let marloRoll = range(.marlo) { $0.lean }, kikoRoll = range(.kiko) { $0.lean }
            expect(marloRoll > 0.05 && kikoRoll < 0.01, "and rocks as if on waves", "\(marloRoll) against \(kikoRoll)")
        }

        print("only Suzu vanishes")
        do {
            for avatar in [Avatar.kiko, .marlo] {
                let rig = Rig(avatar: avatar)
                _ = hold(rig, centre, 0.5)
                let pose = hold(rig, centre, 0.1, buttons: 1)
                expect(pose.vanish == 0 && pose.puffs.isEmpty, "\(avatar.name) stays put on a click")
            }
        }

        print("swapping characters")
        do {
            let rig = Rig()
            _ = hold(rig, centre, 0.5)
            let before = hold(rig, centre, 0.05, buttons: 1)
            expect(!before.sparkles.isEmpty, "Kiko's sparkles are in the air")
            _ = hold(rig, centre, 0.5)
            for avatar in [Avatar.suzu, .marlo, .kiko, .marlo, .suzu] {
                // Whatever the last one threw is still in the air when the swap comes.
                _ = hold(rig, centre, 0.05, buttons: 1)
                rig.avatar = avatar
                let pose = rig.step(RigInput(dt: dt, mouse: centre, screen: screen))
                let fresh = Rig(avatar: avatar)
                let freshPose = hold(fresh, centre, dt)
                expect(pose.avatar == avatar, "swapped to \(avatar.name)")
                expect(pose.sparkles.isEmpty && pose.puffs.isEmpty, "nothing of the last character's is left flying")
                expect(hypot(pose.body.x - before.body.x, pose.body.y - before.body.y) < 12, "the body stays put", "\(pose.body)")
                expect(pose.scarfA.count == freshPose.scarfA.count && pose.scarfB.count == freshPose.scarfB.count, "its chains are rebuilt",
                       "\(pose.scarfA.count)/\(pose.scarfB.count) against \(freshPose.scarfA.count)/\(freshPose.scarfB.count)")
                expect((pose.scarfA + pose.scarfB).allSatisfy { hypot($0.x - pose.body.x, $0.y - pose.body.y) < 75 }, "and attached")
                expect(pose.fingerTip == .zero, "the fingertip doesn't move")

                // From here on it behaves as that character does from the start.
                _ = hold(rig, centre, 0.5)
                _ = hold(fresh, centre, 0.5)
                let clicked = hold(rig, centre, 0.1, buttons: 1), freshClick = hold(fresh, centre, 0.1, buttons: 1)
                expect(clicked.vanish == freshClick.vanish && clicked.puffs.count == freshClick.puffs.count
                       && clicked.sparkles.count == freshClick.sparkles.count, "and clicks like \(avatar.name)",
                       "vanish \(clicked.vanish), \(clicked.puffs.count) puffs, \(clicked.sparkles.count) thrown")
                _ = hold(rig, centre, 0.5)
            }

            let smoky = Rig(avatar: .suzu)
            _ = hold(smoky, centre, 0.5)
            _ = hold(smoky, centre, 0.05, buttons: 1)
            smoky.avatar = .marlo
            smoky.avatar = .suzu
            let backAgain = smoky.step(RigInput(dt: dt, mouse: centre, screen: screen))
            expect(backAgain.vanish == 0, "swapping away and back doesn't leave her in the smoke", "\(backAgain.vanish)")

            let asleep = Rig()
            _ = hold(asleep, centre, 28)
            asleep.avatar = .marlo
            expect(hold(asleep, centre, 0.2).expression == .asleep, "swapping doesn't wake anyone up")
        }

        print("everyone looks different")
        do {
            let ctx = inkCanvas()
            var images: [Avatar: [UInt8]] = [:]
            for avatar in Avatar.allCases {
                render(hold(Rig(avatar: avatar), centre, 1), ctx)
                images[avatar] = allPixels(ctx)
            }
            for (a, b) in [(Avatar.kiko, Avatar.suzu), (.kiko, .marlo), (.suzu, .marlo)] {
                let n = differingPixels(images[a]!, images[b]!)
                expect(n > 800, "\(a.name) and \(b.name) are clearly different drawings", "only \(n) px differ")
            }
        }
    }
}
