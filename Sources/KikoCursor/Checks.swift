import CoreGraphics
import Foundation
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

    static func run() -> Bool {
        failures = 0
        let centre = CGPoint(x: 700, y: 480)

        print("pointer accuracy")
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

        print("leash and window")
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
            expect(minD >= Rig.minBodyDistance - 0.5, "body never sits on the pointer", "min \(minD)")
            expect(maxD <= Rig.maxBodyDistance + 0.5, "arm never over-stretches", "max \(maxD)")
            expect(maxExtent <= Rig.halfExtent, "every pose fits the window", "extent \(maxExtent)")
        }

        print("screen edges")
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

        print("reactions")
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

            expect(hold(Rig(), centre, 1, kind: .link).expression == .excited, "links make Kiko excited")
        }

        print("getting out of the way")
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

        print("stability")
        do {
            let rig = Rig()
            // Long frames (a stalled main thread) and a jump across displays must not explode.
            var pose = hold(rig, centre, 0.5)
            for _ in 0..<20 { pose = rig.step(RigInput(dt: 0.5, mouse: centre, screen: screen)) }
            pose = rig.step(RigInput(dt: dt, mouse: CGPoint(x: 4000, y: 2000), screen: CGRect(x: 3000, y: 1000, width: 2000, height: 1500)))
            let d = hypot(pose.body.x, pose.body.y)
            expect(d.isFinite && d < 100, "survives stalls and a jump between displays", "\(d)")
            expect(pose.scarfA.allSatisfy { $0.x.isFinite && abs($0.x) < 120 }, "scarf stays attached after a jump")
        }

        print(failures == 0 ? "all checks passed" : "\(failures) check(s) FAILED")
        return failures == 0
    }
}
