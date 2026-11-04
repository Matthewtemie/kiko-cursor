import CoreGraphics
import Foundation

public struct RigInput {
    public var dt: Double
    public var mouse: CGPoint       // global points, y down
    public var buttons: Int         // NSEvent.pressedMouseButtons
    public var kind: CursorKind
    public var screen: CGRect       // display under the mouse, global points, y down
    public var typing: Bool         // a key was pressed since the mouse last moved
    public var hiddenWhenIdle: Bool // fullscreen video and the like: vanish once idle

    public init(dt: Double, mouse: CGPoint, buttons: Int = 0, kind: CursorKind = .arrow,
                screen: CGRect, typing: Bool = false, hiddenWhenIdle: Bool = false) {
        self.dt = dt
        self.mouse = mouse
        self.buttons = buttons
        self.kind = kind
        self.screen = screen
        self.typing = typing
        self.hiddenWhenIdle = hiddenWhenIdle
    }
}

private struct Spring {
    var x: CGFloat
    var v: CGFloat = 0

    mutating func step(to target: CGFloat, omega: CGFloat, zeta: CGFloat, dt: CGFloat) {
        // A stiff spring overshoots further each time once a tick gets long, and then grows without
        // limit. So a long tick is taken in steps no longer than a 60 Hz one.
        let steps = max(1, Int((dt * 60 - 1e-9).rounded(.up)))
        let h = dt / CGFloat(steps)
        for _ in 0..<steps {
            v += (omega * omega * (target - x) - 2 * zeta * omega * v) * h
            x += v * h
        }
    }
}

private struct Chain {
    var pts: [CGPoint]
    var prev: [CGPoint]
    let seg: CGFloat

    init(at p: CGPoint, nodes: Int, seg: CGFloat, side: CGFloat = 1) {
        pts = (0..<nodes).map { CGPoint(x: p.x + side * CGFloat($0) * seg, y: p.y + CGFloat($0) * seg * 0.4) }
        prev = pts
        self.seg = seg
    }

    mutating func step(anchor: CGPoint, force: CGPoint, dt: CGFloat) {
        pts[0] = anchor
        prev[0] = anchor
        let damping: CGFloat = pow(0.02, dt)
        for i in 1..<pts.count {
            let vx = (pts[i].x - prev[i].x) * damping
            let vy = (pts[i].y - prev[i].y) * damping
            prev[i] = pts[i]
            pts[i].x += vx + force.x * dt * dt
            pts[i].y += vy + force.y * dt * dt
        }
        for _ in 0..<3 {
            for i in 1..<pts.count {
                let dx = pts[i].x - pts[i - 1].x, dy = pts[i].y - pts[i - 1].y
                let d = max(hypot(dx, dy), 0.001)
                let k = (d - seg) / d
                if i == 1 {
                    pts[i].x -= dx * k
                    pts[i].y -= dy * k
                } else {
                    pts[i].x -= dx * k * 0.5
                    pts[i].y -= dy * k * 0.5
                    pts[i - 1].x += dx * k * 0.5
                    pts[i - 1].y += dy * k * 0.5
                }
            }
        }
        // A few relaxation passes can't keep up with a really fast flick, so also cap each
        // node's reach from the knot. Without this the ribbon outruns the window and clips.
        for i in 1..<pts.count {
            let dx = pts[i].x - anchor.x, dy = pts[i].y - anchor.y
            let d = hypot(dx, dy)
            let reach = seg * CGFloat(i)
            if d > reach {
                pts[i] = CGPoint(x: anchor.x + dx / d * reach, y: anchor.y + dy / d * reach)
            }
        }
    }

    func relative(to o: CGPoint) -> [CGPoint] {
        pts.map { CGPoint(x: $0.x - o.x, y: $0.y - o.y) }
    }
}

private struct Particle {
    var pos: CGPoint
    var vel: CGPoint
    var age: CGFloat = 0
    let life: CGFloat
    let size: CGFloat
    let spin: CGFloat
}

/// Turns mouse input into a Pose. Holds no AppKit state, so it can be driven by a
/// scripted input for the contact sheet and the checks.
public final class Rig {
    /// The window must reach this far from the hotspot to contain any pose.
    public static let halfExtent: CGFloat = 128
    public static let minBodyDistance: CGFloat = 24
    public static let maxBodyDistance: CGFloat = 62

    /// Swaps the character in place. The body stays where it is, so nothing jumps.
    public var avatar: Avatar {
        didSet {
            guard avatar != oldValue else { return }
            motion = avatar.motion
            sparkles.removeAll()
            puffs.removeAll()
            poofStart = -10
            vanishAtClick = 0
            buildChains()
        }
    }

    public private(set) var expression = Expression.neutral
    public private(set) var idleSeconds: Double = 0

    private var initialized = false
    private var time: CGFloat = 0
    private var lastMouse = CGPoint.zero
    private var vel = CGPoint.zero
    private var bodyPos = CGPoint.zero
    private var bodyVel = CGPoint.zero
    private var sideX: CGFloat = 1
    private var sideY: CGFloat = 1

    private var facing = Spring(x: 1)
    private var lean = Spring(x: 0)
    private var headTilt = Spring(x: 0)
    private var squash = Spring(x: 1)
    private var tail = Spring(x: -0.75)
    private var earL = Spring(x: 0)
    private var earR = Spring(x: 0)
    private var turn = Spring(x: 0)
    private var lookX = Spring(x: 0)
    private var lookY = Spring(x: 0)
    private var reach = Spring(x: 1)
    private var hover = Spring(x: 0)
    private var drowse = Spring(x: 0)
    private var opacity: CGFloat = 1

    private var motion: Motion
    private var chainA: Chain
    private var chainB: Chain
    private var sparkles: [Particle] = []
    private var puffs: [Particle] = []
    private var zees: [Particle] = []
    private var poofStart: CGFloat = -10
    private var vanishAtClick: CGFloat = 0

    private var legPhase: CGFloat = 0
    private var blinkClock: CGFloat = 2
    private var blinkT: CGFloat = 1
    private var nextEarFlick: CGFloat = 4
    private var nextZee: CGFloat = 0
    private var happyUntil: CGFloat = 0
    private var dizzyUntil: CGFloat = 0
    private var surprisedUntil: CGFloat = 0
    private var buttonHeld: CGFloat = 0
    private var lastButtons = 0
    private var lastDirX: CGFloat = 0
    private var reversals: [CGFloat] = []
    private var rng: UInt64

    public init(seed: UInt64 = 0x4B494B4F, avatar: Avatar = .kiko) {
        rng = seed
        self.avatar = avatar
        motion = avatar.motion
        chainA = Chain(at: .zero, nodes: motion.chainA.nodes, seg: motion.chainA.seg)
        chainB = Chain(at: .zero, nodes: motion.chainB.nodes, seg: motion.chainB.seg)
    }

    private func random() -> CGFloat {
        // SplitMix64, so that scripted runs are repeatable.
        rng &+= 0x9E3779B97F4A7C15
        var z = rng
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        z ^= z >> 31
        return CGFloat(z >> 11) / CGFloat(UInt64(1) << 53)
    }

    /// True while anything is visibly in motion, so the caller can draw at full rate.
    public var isLively: Bool {
        let moving = hypot(vel.x, vel.y) > 3 || hypot(bodyVel.x, bodyVel.y) > 3
        let posing = abs(hover.v) > 0.05 || abs(drowse.v) > 0.05 || !puffs.isEmpty
        return moving || posing || abs(squash.v) > 0.05 || !sparkles.isEmpty || buttonHeld > 0 || abs(lean.v) > 0.02 + motion.rollSize * motion.rollRate
    }

    public func step(_ input: RigInput) -> Pose {
        let dt = CGFloat(min(max(input.dt, 1.0 / 240), 1.0 / 24))
        let mouse = input.mouse
        if !initialized || hypot(mouse.x - lastMouse.x, mouse.y - lastMouse.y) > 900 {
            reset(at: mouse, screen: input.screen)
        }
        time += dt

        let rawVel = CGPoint(x: (mouse.x - lastMouse.x) / dt, y: (mouse.y - lastMouse.y) / dt)
        lastMouse = mouse
        let blend = 1 - exp(-dt * 22)
        vel.x += (rawVel.x - vel.x) * blend
        vel.y += (rawVel.y - vel.y) * blend
        let speed = hypot(vel.x, vel.y)

        updateClicks(input, speed: speed)
        updateShake(speed: speed)
        updateExpression(input, speed: speed, dt: dt)
        updateBody(input, dt: dt)

        let rel = CGPoint(x: bodyPos.x - mouse.x, y: bodyPos.y - mouse.y)
        if rel.x > 9 { facingTarget = 1 } else if rel.x < -9 { facingTarget = -1 }
        facing.step(to: facingTarget, omega: 24, zeta: 0.85, dt: dt)
        let sign: CGFloat = facing.x < 0 ? -1 : 1

        let sleeping = expression == .asleep
        let leanTarget = clamp(vel.x * 0.00032, -0.34, 0.34) + sin(time * motion.rollRate) * motion.rollSize
        lean.step(to: leanTarget, omega: 13, zeta: 0.42, dt: dt)
        let nod = sleeping ? 0.1 + 0.05 * sin(time * 1.2) : 0
        headTilt.step(to: lean.x * 0.55 + (sleeping ? nod : 0.04 * sin(time * 0.9)), omega: 10, zeta: 0.5, dt: dt)

        let squashTarget: CGFloat = input.buttons != 0 ? 0.88 : 1 + min(speed / 9000, 0.05)
        squash.step(to: squashTarget, omega: 34, zeta: 0.32, dt: dt)

        let happyNow = expression == .happy || expression == .excited
        let wagRate: CGFloat = happyNow ? 13 : (sleeping ? 1.1 : 2.3)
        let wagSize: CGFloat = happyNow ? 0.3 : (sleeping ? 0.06 : 0.12)
        let tailTarget = -0.75 + wagSize * sin(time * wagRate) + clamp(vel.x * sign * 0.00065, -0.8, 0.8) + (sleeping ? 0.55 : 0)
        tail.step(to: tailTarget, omega: 11, zeta: 0.4, dt: dt)

        updateEars(input, speed: speed, sign: sign, dt: dt)
        updateLook(rel: rel, speed: speed, sign: sign, dt: dt)
        updateBlink(dt: dt)

        reach.step(to: input.kind == .other ? 0 : 1, omega: 18, zeta: 1, dt: dt)
        reach.x = clamp(reach.x, 0, 1)
        hover.step(to: input.kind == .link && !sleeping ? 1 : 0, omega: 16, zeta: 0.6, dt: dt)
        hover.x = clamp(hover.x, 0, 1.15)
        drowse.step(to: sleeping ? 1 : 0, omega: 6, zeta: 1, dt: dt)
        drowse.x = clamp(drowse.x, 0, 1)

        legPhase += min(speed, 2500) * dt * 0.024
        let legAmount = min(speed / 700, 1)

        // Asleep is slow breathing instead of the bob. Drowse blends them, so there's no jump between.
        let awakeBob = sin(time * motion.bobRate) * motion.bobSize
        let bob = awakeBob + (sin(time * 1.2) * 0.9 - awakeBob) * drowse.x
        let breeze = sin(time * 1.7) * 55
        chainA.step(anchor: anchor(motion.chainA, sign: sign, bob: bob),
                    force: CGPoint(x: sign * motion.chainA.pull.x + breeze * motion.chainA.breeze, y: motion.chainA.pull.y), dt: dt)
        chainB.step(anchor: anchor(motion.chainB, sign: sign, bob: bob),
                    force: CGPoint(x: sign * motion.chainB.pull.x + breeze * motion.chainB.breeze, y: motion.chainB.pull.y), dt: dt)
        // Flutter travelling down the ribbon, stronger the faster Kiko is going.
        let flutter = 1.2 + min(speed / 450, 1) * 2.2

        updateParticles(input, dt: dt, sign: sign)

        let hide = input.hiddenWhenIdle && idleSeconds > 2
        let opacityTarget: CGFloat = hide ? 0 : (input.typing ? 0.25 : 1)
        opacity += (opacityTarget - opacity) * (1 - exp(-dt * (opacityTarget > opacity ? 26 : 7)))

        var pose = Pose()
        pose.avatar = avatar
        pose.body = CGPoint(x: rel.x, y: rel.y)
        pose.facing = facing.x
        pose.lean = lean.x
        pose.squash = squash.x
        pose.bob = bob
        pose.headTilt = headTilt.x
        pose.turn = turn.x
        pose.look = CGPoint(x: lookX.x, y: lookY.x)
        pose.blink = blinkValue
        pose.expression = expression
        pose.earL = earL.x
        pose.earR = earR.x
        pose.tailAngle = tail.x
        pose.legSwing = sin(legPhase) * legAmount
        pose.armSwing = sin(legPhase + 1.2) * legAmount
        pose.reach = reach.x
        pose.fingerTip = fingerTip(rel: rel, sign: sign)
        pose.scarfA = fluttered(chainA.relative(to: mouse), amount: flutter * motion.chainA.flutter, phase: motion.chainA.phase)
        pose.scarfB = fluttered(chainB.relative(to: mouse), amount: flutter * motion.chainB.flutter, phase: motion.chainB.phase)
        pose.hover = hover.x
        pose.drowse = drowse.x
        pose.vanish = vanish
        pose.sparkles = sparkles.map {
            let pos = CGPoint(x: $0.pos.x - mouse.x, y: $0.pos.y - mouse.y)
            return Sparkle(pos: pos,
                           size: $0.size * (1 - $0.age / $0.life * motion.burst.shrink),
                           rot: $0.spin * $0.age,
                           alpha: (1 - pow($0.age / $0.life, 3)) * edgeFade(pos, margin: 8))
        }
        pose.puffs = puffs.map {
            let pos = CGPoint(x: $0.pos.x - mouse.x, y: $0.pos.y - mouse.y)
            let radius = $0.size * (0.7 + 0.8 * sqrt($0.age / $0.life))
            return Puff(pos: pos, radius: radius, alpha: (1 - pow($0.age / $0.life, 2)) * edgeFade(pos, margin: radius), turn: $0.spin)
        }
        pose.zees = zees.map {
            Zee(pos: CGPoint(x: $0.pos.x - mouse.x, y: $0.pos.y - mouse.y),
                size: $0.size * (0.7 + 0.5 * $0.age / $0.life),
                alpha: min($0.age * 4, 1) * (1 - pow($0.age / $0.life, 2)))
        }
        pose.opacity = opacity
        return pose
    }

    private var facingTarget: CGFloat = 1

    /// A flick can leave what was thrown behind at the edge of the window, which would
    /// cut it off in a straight line. So it fades out before it gets there.
    private func edgeFade(_ pos: CGPoint, margin: CGFloat) -> CGFloat {
        clamp((Rig.halfExtent - max(abs(pos.x), abs(pos.y)) - margin) / 10, 0, 1)
    }

    /// Gone within a moment of the click and back about a third of a second later.
    private var vanish: CGFloat {
        guard motion.poofs else { return 0 }
        let t = time - poofStart
        // From wherever she'd got to, so a double click doesn't bring her out for a frame.
        if t < 0.05 { return vanishAtClick + (1 - vanishAtClick) * t / 0.05 }
        if t < 0.16 { return 1 }
        if t < 0.34 {
            let back = (t - 0.16) / 0.18
            return 1 - back * back * (3 - 2 * back)
        }
        return 0
    }

    private func anchor(_ spec: ChainSpec, sign: CGFloat, bob: CGFloat) -> CGPoint {
        let x = sign * spec.anchor.x, y = spec.anchor.y
        guard spec.followsBody else { return CGPoint(x: bodyPos.x + x, y: bodyPos.y + y) }
        return CGPoint(x: bodyPos.x + x * cos(lean.x) - y * sin(lean.x),
                       y: bodyPos.y + bob + x * sin(lean.x) + y * cos(lean.x))
    }

    private func buildChains() {
        for (spec, isA) in [(motion.chainA, true), (motion.chainB, false)] {
            let start = CGPoint(x: bodyPos.x + spec.anchor.x * sideX, y: bodyPos.y + spec.anchor.y - 0.5)
            let chain = Chain(at: start, nodes: spec.nodes, seg: spec.seg, side: sideX)
            if isA { chainA = chain } else { chainB = chain }
        }
    }

    private func fluttered(_ pts: [CGPoint], amount: CGFloat, phase: CGFloat) -> [CGPoint] {
        var out = pts
        for i in 1..<pts.count {
            let a = pts[i - 1], b = pts[i]
            let d = max(hypot(b.x - a.x, b.y - a.y), 0.01)
            let along = CGFloat(i) / CGFloat(pts.count - 1)
            let wave = sin(time * 7.5 - CGFloat(i) * 1.15 + phase) * amount * along
            out[i] = CGPoint(x: b.x - (b.y - a.y) / d * wave, y: b.y + (b.x - a.x) / d * wave)
        }
        return out
    }

    private var blinkValue: CGFloat {
        // blinkT runs 0...1 over one blink: shut at the midpoint.
        blinkT >= 1 ? 1 : abs(blinkT * 2 - 1)
    }

    private func clamp(_ v: CGFloat, _ lo: CGFloat, _ hi: CGFloat) -> CGFloat {
        min(max(v, lo), hi)
    }

    private func reset(at mouse: CGPoint, screen: CGRect) {
        initialized = true
        lastMouse = mouse
        vel = .zero
        bodyVel = .zero
        updateSides(mouse, screen)
        let rest = restOffset(mouse, screen, kind: .arrow)
        bodyPos = CGPoint(x: mouse.x + rest.x, y: mouse.y + rest.y)
        facingTarget = sideX
        facing = Spring(x: sideX)
        buildChains()
    }

    private func updateSides(_ mouse: CGPoint, _ screen: CGRect) {
        // Keep the body on the same display as the hotspot, with hysteresis so it
        // does not flip back and forth along an edge.
        if mouse.x > screen.maxX - 95 { sideX = -1 }
        else if mouse.x < screen.minX + 95 { sideX = 1 }
        else if sideX < 0 && mouse.x < screen.maxX - 170 { sideX = 1 }

        if mouse.y > screen.maxY - 88 { sideY = -1 }
        else if sideY < 0 && mouse.y < screen.maxY - 150 { sideY = 1 }
    }

    private func restOffset(_ mouse: CGPoint, _ screen: CGRect, kind: CursorKind) -> CGPoint {
        let aside: CGFloat = kind == .other ? 1.22 : 1
        var y: CGFloat = sideY > 0 ? 32 * aside : -36 * aside
        if sideY > 0 {
            // Ears would poke past the top edge, so hang a little lower up there.
            y += max(0, 26 - (mouse.y - screen.minY)) * 0.8
        }
        return CGPoint(x: 36 * aside * sideX, y: y)
    }

    private func updateBody(_ input: RigInput, dt: CGFloat) {
        let mouse = input.mouse
        updateSides(mouse, input.screen)
        let rest = restOffset(mouse, input.screen, kind: input.kind)
        let target = CGPoint(x: mouse.x + rest.x, y: mouse.y + rest.y)

        let omega = motion.omega, zeta = motion.zeta
        bodyVel.x += (omega * omega * (target.x - bodyPos.x) - 2 * zeta * omega * bodyVel.x) * dt
        bodyVel.y += (omega * omega * (target.y - bodyPos.y) - 2 * zeta * omega * bodyVel.y) * dt
        bodyPos.x += bodyVel.x * dt
        bodyPos.y += bodyVel.y * dt

        // Kiko is on a leash: never so far that the arm snaps, never on top of the pointer.
        var rx = bodyPos.x - mouse.x, ry = bodyPos.y - mouse.y
        let d = max(hypot(rx, ry), 0.001)
        let limit = Rig.maxBodyDistance
        if d > limit || d < Rig.minBodyDistance {
            let wanted = d > limit ? limit : Rig.minBodyDistance
            rx *= wanted / d
            ry *= wanted / d
            bodyPos = CGPoint(x: mouse.x + rx, y: mouse.y + ry)
            let radial = (bodyVel.x * rx + bodyVel.y * ry) / (wanted * wanted)
            bodyVel.x -= rx * radial
            bodyVel.y -= ry * radial
        }
    }

    private func fingerTip(rel: CGPoint, sign: CGFloat) -> CGPoint {
        if reach.x >= 0.999 { return .zero }
        let relaxed = CGPoint(x: rel.x + sign * -13, y: rel.y + 12)
        return CGPoint(x: relaxed.x * (1 - reach.x), y: relaxed.y * (1 - reach.x))
    }

    private func updateClicks(_ input: RigInput, speed: CGFloat) {
        let down = input.buttons != 0 && lastButtons == 0
        if down {
            happyUntil = time + 0.55
            squash.v -= 3.2
            burst(at: input.mouse)
            if motion.poofs {
                vanishAtClick = vanish
                poofStart = time
                poof(at: CGPoint(x: bodyPos.x, y: bodyPos.y - 8))
            }
        }
        if input.buttons != 0 { buttonHeld += CGFloat(input.dt) } else { buttonHeld = 0 }
        lastButtons = input.buttons
        if speed > 2600 { surprisedUntil = time + 0.28 }
    }

    private func burst(at p: CGPoint) {
        let b = motion.burst
        for i in 0..<b.count {
            let a = CGFloat(i) / CGFloat(b.count) * .pi * 2 + random() * 0.7
            let v = pick(b.speed)
            sparkles.append(Particle(pos: p,
                                     vel: CGPoint(x: cos(a) * v, y: sin(a) * v - b.lift),
                                     life: pick(b.life),
                                     size: pick(b.size),
                                     spin: (random() - 0.5) * b.spin))
        }
    }

    private func pick(_ range: ClosedRange<CGFloat>) -> CGFloat {
        range.lowerBound + random() * (range.upperBound - range.lowerBound)
    }

    private func poof(at p: CGPoint) {
        for i in 0..<9 {
            let a = CGFloat(i) / 9 * .pi * 2 + random() * 0.5
            let out = i == 0 ? 0 : 12 + random() * 12
            puffs.append(Particle(pos: CGPoint(x: p.x + cos(a) * out, y: p.y + sin(a) * out * 1.25),
                                  vel: CGPoint(x: cos(a) * 26, y: sin(a) * 26 - 8),
                                  life: 0.36 + random() * 0.2,
                                  size: 9 + random() * 6,
                                  spin: a))
        }
    }

    private func updateShake(speed: CGFloat) {
        guard speed > 750 else { return }
        let dir: CGFloat = vel.x > 0 ? 1 : -1
        if abs(vel.x) > 600 && dir != lastDirX {
            if lastDirX != 0 { reversals.append(time) }
            lastDirX = dir
        }
        reversals.removeAll { time - $0 > 0.9 }
        if reversals.count >= 4 {
            dizzyUntil = time + 1.8
            reversals.removeAll()
        }
    }

    private func updateExpression(_ input: RigInput, speed: CGFloat, dt: CGFloat) {
        let still = speed < 6 && input.buttons == 0
        idleSeconds = still ? idleSeconds + Double(dt) : 0

        if time < dizzyUntil { expression = .dizzy }
        else if time < happyUntil { expression = .happy }
        else if buttonHeld > 0.3 { expression = .focused }
        else if time < surprisedUntil { expression = .surprised }
        else if idleSeconds > 25 { expression = .asleep }
        else if input.kind == .link { expression = .excited }
        else { expression = .neutral }
    }

    private func updateEars(_ input: RigInput, speed: CGFloat, sign: CGFloat, dt: CGFloat) {
        var target: CGFloat = 0
        switch expression {
        case .asleep: target = -0.32
        case .excited, .happy: target = 0.13
        case .dizzy: target = -0.22 + 0.2 * sin(time * 9)
        default: break
        }
        target -= min(speed / 3000, 0.4)

        nextEarFlick -= dt
        if nextEarFlick <= 0, expression != .asleep {
            if random() > 0.5 { earL.v -= 7 } else { earR.v -= 7 }
            nextEarFlick = 3 + random() * 6
        }
        earL.step(to: target, omega: 20, zeta: 0.34, dt: dt)
        earR.step(to: target, omega: 20, zeta: 0.34, dt: dt)
    }

    private func updateLook(rel: CGPoint, speed: CGFloat, sign: CGFloat, dt: CGFloat) {
        // In the character's own space: -x is the way it is facing.
        var lx: CGFloat, ly: CGFloat
        if speed > 40 {
            let amount = min(speed / 500, 1)
            lx = vel.x / speed * amount * sign
            ly = vel.y / speed * amount
        } else {
            let d = max(hypot(rel.x, rel.y), 1)
            lx = -rel.x / d * 0.75 * sign
            ly = -rel.y / d * 0.75
        }
        if expression == .asleep { lx = 0; ly = 0 }
        lookX.step(to: lx, omega: 17, zeta: 0.75, dt: dt)
        lookY.step(to: ly, omega: 17, zeta: 0.75, dt: dt)
        turn.step(to: clamp(lx, -1, 1), omega: 10, zeta: 0.8, dt: dt)
    }

    private func updateBlink(dt: CGFloat) {
        if blinkT < 1 {
            blinkT += dt / 0.16
            return
        }
        blinkClock -= dt
        if blinkClock <= 0 {
            blinkT = 0
            blinkClock = 2 + random() * 3.6
        }
    }

    private func updateParticles(_ input: RigInput, dt: CGFloat, sign: CGFloat) {
        for i in sparkles.indices {
            sparkles[i].pos.x += sparkles[i].vel.x * dt
            sparkles[i].pos.y += sparkles[i].vel.y * dt
            sparkles[i].vel.x *= pow(motion.burst.drag, dt)
            sparkles[i].vel.y *= pow(motion.burst.drag, dt)
            sparkles[i].vel.y += motion.burst.gravity * dt
            sparkles[i].age += dt
        }
        sparkles.removeAll { $0.age >= $0.life }

        for i in puffs.indices {
            puffs[i].pos.x += puffs[i].vel.x * dt
            puffs[i].pos.y += puffs[i].vel.y * dt
            puffs[i].vel.x *= pow(0.05, dt)
            puffs[i].vel.y *= pow(0.05, dt)
            puffs[i].age += dt
        }
        puffs.removeAll { $0.age >= $0.life }

        if expression == .asleep {
            nextZee -= dt
            if nextZee <= 0 {
                let start = CGPoint(x: bodyPos.x - sign * 12, y: bodyPos.y - 32)
                zees.append(Particle(pos: start, vel: CGPoint(x: -sign * 6, y: -13), life: 2.3, size: 2.4 + random() * 1.4, spin: 0))
                nextZee = 1.3
            }
        } else {
            zees.removeAll()
            nextZee = 0
        }
        for i in zees.indices {
            zees[i].pos.x += zees[i].vel.x * dt
            zees[i].pos.y += zees[i].vel.y * dt
            zees[i].age += dt
        }
        zees.removeAll { $0.age >= $0.life }
    }
}
