import CoreGraphics

extension Motion {
    /// Quick and light: chain A is the ponytail, chain B the cord with the bell on it.
    static let suzu = Motion(
        omega: 16, zeta: 0.74,
        bobSize: 0.45, bobRate: 2.8,
        rollSize: 0, rollRate: 0,
        chainA: ChainSpec(nodes: 7, seg: 5, anchor: CGPoint(x: 15.5, y: -25), pull: CGPoint(x: 110, y: 205),
                          breeze: 0.5, flutter: 0.7, phase: 0, followsBody: true),
        chainB: ChainSpec(nodes: 5, seg: 2.2, anchor: CGPoint(x: 8.2, y: 10.6), pull: CGPoint(x: 205, y: 520),
                          breeze: 0.2, flutter: 0.12, phase: 1.2, followsBody: true),
        burst: Burst(count: 5, speed: 120...200, life: 0.34...0.48, size: 3.2...4.4, spin: 22, drag: 0.04, shrink: 0.25),
        poofs: true)
}

private enum Ink {
    static let line = Line.ink
    static let halo = Line.halo
    static let skin = rgb(0xFFE4D0)
    static let skinShade = rgb(0xF3C2A9)
    static let hood = rgb(0x1F8A8C)
    static let hoodDark = rgb(0x15686B)
    static let hoodLight = rgb(0x52BDB8)
    static let hoodInside = rgb(0x0E464C)
    static let hair = rgb(0x6C3A7E)
    static let hairDark = rgb(0x4C2860)
    static let hairLight = rgb(0xA671BD)
    static let cloth = rgb(0x5A5F78)
    static let clothDark = rgb(0x454960)
    static let leg = rgb(0x3A3C52)
    static let tabi = rgb(0xEFEBE3)
    static let sash = rgb(0xA85B6E)
    static let sashDark = rgb(0x7E3F52)
    static let cord = rgb(0xC4573F)
    static let brass = rgb(0xDBA43C)
    static let brassDark = rgb(0x9C6A1D)
    static let brassLight = rgb(0xFAE29A)
    static let paper = rgb(0xF7F0DF)
    static let paperShade = rgb(0xD9CDB2)
    static let smoke = rgb(0xF6F2EB)
    static let smokeShade = rgb(0xD5D0D6)
    static let blush = rgb(0xFF7E8B, 0.5)
    static let mouth = rgb(0x8E2B3B)
    static let tongue = rgb(0xFF8A94)
    static let iris = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                                 colors: [rgb(0x6A3107), rgb(0xC8761C), rgb(0xFFD062)] as CFArray,
                                 locations: [0, 0.55, 1])!
}

/// Fixed outlines, built once. Head shapes are centred on the head; everything is in points.
private enum Shape {
    // MARK: Hood

    /// The outside of the hood, and so most of her silhouette.
    static let hood = path {
        $0.m(-13.5, 15.5); $0.c(-19.5, 11, -22, 3, -21.5, -6)
        $0.c(-21, -18, -11.5, -26.5, 0.5, -26.5); $0.c(12, -26.5, 21.5, -18, 21.5, -6)
        $0.c(22, 3, 19.5, 11, 13.5, 15.5); $0.q(0, 19, -13.5, 15.5); $0.z()
    }
    /// The point of the hood, swept back. Origin is its pivot, buried inside the hood.
    static let hoodTip = path {
        $0.m(-7, 3); $0.c(-4, -2.2, 3, -4.2, 9.6, -3.6); $0.q(12.2, -3.2, 11.6, -1)
        $0.q(10.8, 1.8, 9, 5); $0.z()
    }
    static let hoodTipFold = path {
        $0.m(2, -0.4); $0.q(5.6, -2, 9.2, -2.2)
    }
    /// The side of the hood in shadow, away from the pointing arm.
    static let hoodShade = path {
        $0.m(9, -24.8); $0.c(16, -21.5, 21.5, -15, 21.5, -6); $0.c(22, 3, 19.5, 11, 13.5, 15.5); $0.q(9, 16.8, 5, 17)
        $0.c(13, 13, 17.5, 5, 17.6, -4); $0.c(17.8, -12, 15, -20, 9, -24.8); $0.z()
    }
    static let hoodFolds = path {
        $0.m(-16.5, -18.5); $0.q(-12, -22.5, -6, -24)
        $0.m(-19.6, 3); $0.q(-20.2, 8, -16.5, 12)
    }
    /// The hole her face looks out of.
    static let opening = path {
        $0.m(-16.8, 3); $0.c(-18, -9, -10.5, -18, 0, -18); $0.c(10.5, -18, 18, -9, 16.8, 3)
        $0.c(16, 9.5, 8.5, 15, 0, 16); $0.c(-8.5, 15, -16, 9.5, -16.8, 3); $0.z()
    }
    /// A lighter hem, just outside the opening.
    static let hem = path {
        $0.m(-18.6, 3.2); $0.c(-20, -10.5, -11.5, -19.8, 0, -19.8); $0.c(11.5, -19.8, 20, -10.5, 18.6, 3.2)
        $0.c(17.8, 10.5, 9.5, 16.5, 0, 17.8); $0.c(-9.5, 16.5, -17.8, 10.5, -18.6, 3.2); $0.z()
    }

    // MARK: Face and hair

    static let face = path {
        $0.m(-16.5, -3); $0.c(-16.5, -14, -8, -19, 0, -19); $0.c(8, -19, 16.5, -14, 16.5, -3)
        $0.c(16.5, 5, 8, 12.4, 0, 14.6); $0.c(-8, 12.4, -16.5, 5, -16.5, -3); $0.z()
    }
    /// A soft fringe swept toward the pointing arm, parted on the far side, running down
    /// into a lock on each side of the face so that the face has one clean edge.
    static let fringe = path {
        $0.m(-22, 14); $0.c(-23, -12, -11, -22, 1, -22); $0.c(13, -22, 23, -12, 22, 14)
        $0.l(15.2, 11.2); $0.c(13.4, 6, 14.4, -2, 12.6, -6.4); $0.q(11, -10.4, 8, -13)
        $0.c(6.5, -9.2, 3, -6.6, -1.5, -5.8); $0.q(-1.2, -7.6, -0.2, -8.8)
        $0.c(-3, -6.2, -7, -4.8, -10.5, -4.6); $0.q(-10.4, -6.2, -9.6, -7.4)
        $0.c(-12.2, -5, -13.6, 0, -13.2, 4.6); $0.c(-13, 8, -13.6, 10.4, -15.2, 12.2)
        $0.z()
    }
    static let hairShine = path {
        $0.m(-10.5, -12.6); $0.q(-6, -15.4, -1, -15.8)
    }
    /// Upper lash of the calm, half-lidded eye: +x is the outer corner.
    static let lash = path {
        $0.m(-4.9, -2.5); $0.q(-3.4, -4.6, 0, -4.8); $0.q(3.4, -4.8, 5, -3.2)
        $0.q(6.3, -2.7, 7, -4.1); $0.q(6.9, -1.6, 4.8, -1.9)
        $0.q(3.4, -3.4, 0, -3.5); $0.q(-3.2, -3.4, -4.9, -2.5); $0.z()
    }
    /// The eyelid above that lash. Same space, painted in skin over the top of the eye.
    static let lid = path {
        $0.m(-5.4, -2.2); $0.q(-3.4, -4.6, 0, -4.8); $0.q(3.4, -4.8, 5.4, -2.9)
        $0.l(5.4, -7); $0.l(-5.4, -7); $0.z()
    }
    /// The wide-awake lash, with the whole eye showing.
    static let lashWide = path {
        $0.m(-5.3, -2.8); $0.q(-4.8, -6.4, 0, -6.8); $0.q(4.6, -6.6, 5.6, -3.2)
        $0.q(6.6, -2.7, 7.2, -4); $0.q(7, -1.5, 5.1, -1.8)
        $0.q(4, -5, 0, -5.2); $0.q(-3.8, -5, -5.3, -2.8); $0.z()
    }

    // MARK: Body

    static let torso = path {
        $0.m(-7, -1); $0.c(-9.4, 3, -9.8, 7, -9.8, 11); $0.c(-10.4, 13, -11.2, 15, -11.2, 17.6)
        $0.q(0, 20.6, 11.2, 17.6); $0.c(11.2, 15, 10.4, 13, 9.8, 11); $0.c(9.8, 7, 9.4, 3, 7, -1); $0.z()
    }
    static let sash = path {
        $0.m(-10, 8.9); $0.q(0, 11.3, 10, 8.9); $0.l(10.3, 12.9); $0.q(0, 15.5, -10.3, 12.9); $0.z()
    }
    /// The bottom of the hood, draped round the neck.
    static let cowl = path {
        $0.m(-10.5, -3); $0.q(0, -5, 10.5, -3); $0.q(12.8, 1.2, 9.8, 4.6)
        $0.q(4.6, 6.2, 0, 8.6); $0.q(-4.6, 6.2, -9.8, 4.6); $0.q(-12.8, 1.2, -10.5, -3); $0.z()
    }

    // MARK: Bell

    /// Bell, hanging from the origin with +y along the cord.
    static let bell = path {
        $0.addEllipse(in: CGRect(x: -3.9, y: 0.7, width: 7.8, height: 7.8))
    }
    static let bellShade = path {
        $0.m(-3.4, 6.6); $0.q(1.4, 8, 3.8, 3.5); $0.q(4, 8.4, 0, 8.5); $0.q(-2.2, 8.5, -3.4, 6.6); $0.z()
    }
    static let bellSlit = path {
        $0.m(0, 5.3); $0.l(0, 8.3)
    }
    static let bellShine = CGRect(x: -2.5, y: 1.9, width: 2.2, height: 1.8)

    // MARK: Scroll

    static let scrollRoll = CGPath(roundedRect: CGRect(x: -9.2, y: -3.3, width: 18.4, height: 6.6),
                                   cornerWidth: 1.6, cornerHeight: 1.6, transform: nil)
    static let scrollKnobs = path {
        $0.addRoundedRect(in: CGRect(x: -11.4, y: -1.7, width: 3, height: 3.4), cornerWidth: 0.9, cornerHeight: 0.9)
        $0.addRoundedRect(in: CGRect(x: 8.4, y: -1.7, width: 3, height: 3.4), cornerWidth: 0.9, cornerHeight: 0.9)
    }
    static let scrollShade = CGRect(x: -9.2, y: 1.1, width: 18.4, height: 2.2)
    static let scrollBand = CGRect(x: -6.4, y: -3.3, width: 2.4, height: 6.6)

    // MARK: Things in the air

    /// Soft clouds of uneven round lobes, whose tops reach about radius 1. Each lobe is its
    /// share of the way round and how far its curve is pulled out.
    static let clouds: [CGPath] = [
        [(1.0, 1.24), (1.2, 1.3), (0.8, 1.14), (1.1, 1.27), (0.9, 1.18), (1.0, 1.24)],
        [(1.4, 1.34), (0.8, 1.12), (1.15, 1.28), (0.9, 1.16), (1.25, 1.32)],
        [(0.85, 1.16), (1.25, 1.3), (0.8, 1.1), (1.2, 1.29), (0.85, 1.14), (1.0, 1.22), (1.05, 1.24)],
    ].map { lobes in
        let total = lobes.reduce(0) { $0 + $1.0 }
        return path { p in
            var a: CGFloat = 0
            p.m(0.8, 0)
            for (share, reach) in lobes {
                let span = share / total * .pi * 2
                let c = a + span / 2
                a += span
                p.q(cos(c) * reach, sin(c) * reach, cos(a) * 0.8, sin(a) * 0.8)
            }
            p.z()
        }
    }
    /// A folded paper star, radius 1.
    static let shuriken = path {
        let t: CGFloat = 0.3
        $0.m(1, 0); $0.l(t, t); $0.l(0, 1); $0.l(-t, t); $0.l(-1, 0); $0.l(-t, -t); $0.l(0, -1); $0.l(t, -t); $0.z()
    }
    /// One half of each point, the side of the fold in shadow.
    static let shurikenFold = path {
        let t: CGFloat = 0.3
        $0.m(0, 0); $0.l(1, 0); $0.l(t, t); $0.z()
        $0.m(0, 0); $0.l(0, 1); $0.l(-t, t); $0.z()
        $0.m(0, 0); $0.l(-1, 0); $0.l(-t, -t); $0.z()
        $0.m(0, 0); $0.l(0, -1); $0.l(t, -t); $0.z()
    }
}

/// Suzu, a young ninja: a teal hood, a plum ponytail, a small brass bell on a cord.
enum SuzuArt {
    static func draw(_ pose: Pose, in ctx: CGContext) {
        let thickest = pose.puffs.map(\.alpha).max() ?? 0
        let clearAir = pose.puffs.isEmpty && pose.sparkles.isEmpty
        // Once she starts to come back the smoke has begun to fade, and she steps out in front of
        // it, crisp, instead of showing through it like something under glass. Until then it's
        // on top of her, and the arm goes over it all, because nothing may cover the fingertip.
        let steppingOut = !clearAir && pose.vanish < 0.85 && thickest < 0.95
        if steppingOut {
            drawPuffs(ctx, pose, clearSpace: false)
            drawShuriken(ctx, pose)
        }
        for halo in [true, false] {
            let p = Painter(ctx: ctx, halo: halo)
            inChainSpace(ctx, pose) { drawPonytail(p, pose) }
            inHerSpace(ctx, pose) { drawLowerBody(p, pose) }
            inChainSpace(ctx, pose) { drawBell(p, pose) }
            if pose.reach < 0.5 {
                // Beside a text cursor the arm isn't the pointer, so it vanishes with the rest of her.
                inChainSpace(ctx, pose) { drawArm(p, pose) }
            } else if clearAir || steppingOut {
                drawArm(p, pose)
            }
            inHerSpace(ctx, pose) {
                drawUpperBody(p, pose)
                drawHead(p, pose)
            }
        }
        if !clearAir && !steppingOut {
            drawPuffs(ctx, pose, clearSpace: true)
            drawShuriken(ctx, pose)
            if pose.reach >= 0.5 { drawArmOverSmoke(ctx, pose) }
        }
        Kit.zees(ctx, pose, color: Ink.hair)
        Kit.handOnTop(ctx, pose, skin: Ink.skin)
    }

    private static func drawArm(_ p: Painter, _ pose: Pose) {
        Kit.pointingArm(p, pose, sleeve: Ink.cloth, cuff: Ink.hoodLight, skin: Ink.skin)
    }

    private static let everywhere = CGRect(x: -400, y: -400, width: 800, height: 800)

    /// Clips away whatever `add` adds to the path.
    private static func cutOut(_ ctx: CGContext, _ add: () -> Void) {
        ctx.addRect(everywhere)
        add()
        ctx.clip(using: .evenOdd)
    }

    /// Nothing in the air may cover the fingertip, so the arm goes on top of it, in its own two
    /// passes. For the moment she's still shrinking it's masked to look as it does with clear
    /// air: behind her head and cowl, with no white edge across her tunic.
    private static func drawArmOverSmoke(_ ctx: CGContext, _ pose: Pose) {
        ctx.saveGState()
        if pose.vanish < 1 {
            cutOut(ctx) {
                inHerSpace(ctx, pose) {
                    Kit.inHeadSpace(ctx, pose) {
                        ctx.translateBy(x: 0, y: headDrop(pose))
                        ctx.addPath(Shape.hood)
                    }
                }
            }
            cutOut(ctx) { inHerSpace(ctx, pose) { ctx.addPath(Shape.cowl) } }
        }

        ctx.saveGState()
        if pose.vanish < 1 { cutOut(ctx) { inHerSpace(ctx, pose) { ctx.addPath(Shape.torso) } } }
        drawArm(Painter(ctx: ctx, halo: true), pose)
        ctx.restoreGState()

        drawArm(Painter(ctx: ctx, halo: false), pose)
        ctx.restoreGState()
        drawShoulderPuff(ctx, pose)
    }

    /// Where the pointing arm joins her, the same place the Kit starts it from.
    private static func shoulder(_ pose: Pose) -> CGPoint {
        let sign: CGFloat = pose.facing < 0 ? -1 : 1
        let lx = sign * -7.8, ly: CGFloat = 3.5
        return CGPoint(x: pose.body.x + lx * cos(pose.lean) - ly * sin(pose.lean),
                       y: pose.body.y + pose.bob + lx * sin(pose.lean) + ly * cos(pose.lean))
    }

    /// Body space, except that she vanishes toward her shoulder and not her middle. The arm stays
    /// put while she shrinks, so this way it's still joined to her as she grows back.
    private static func inHerSpace(_ ctx: CGContext, _ pose: Pose, _ draw: () -> Void) {
        guard pose.vanish > 0 else { Kit.inBodySpace(ctx, pose, draw); return }
        let at = shoulder(pose)
        let gone = pose.vanish * 0.96
        ctx.saveGState()
        ctx.translateBy(x: (at.x - pose.body.x) * gone, y: (at.y - pose.body.y - pose.bob) * gone)
        Kit.inBodySpace(ctx, pose, draw)
        ctx.restoreGState()
    }

    /// The two chains are drawn outside body space, so they have to vanish along with her.
    private static func inChainSpace(_ ctx: CGContext, _ pose: Pose, _ draw: () -> Void) {
        guard pose.vanish > 0 else { draw(); return }
        let k = 1 - pose.vanish * 0.96
        let at = shoulder(pose)
        ctx.saveGState()
        ctx.translateBy(x: at.x, y: at.y)
        ctx.scaleBy(x: k, y: k)
        ctx.translateBy(x: -at.x, y: -at.y)
        draw()
        ctx.restoreGState()
    }

    // MARK: Chains

    /// A chain hangs straight, which makes a ponytail look like a stick. This bows it.
    private static func bowed(_ pts: [CGPoint], side: CGFloat, by bow: CGFloat) -> [CGPoint] {
        guard let first = pts.first, let last = pts.last else { return pts }
        let dx = last.x - first.x, dy = last.y - first.y
        let d = max(hypot(dx, dy), 0.01)
        var out = pts
        for i in pts.indices {
            let s = sin(CGFloat(i) / CGFloat(pts.count - 1) * .pi) * bow * side
            out[i].x += dy / d * s
            out[i].y -= dx / d * s
        }
        return out
    }

    private static func drawPonytail(_ p: Painter, _ pose: Pose) {
        guard pose.scarfA.count > 5 else { return }
        // Which way it bows swings across as she turns, instead of snapping.
        let side = max(min(pose.facing * 3, 1), -1)
        let chain = Kit.tucked(pose.scarfA, pose)
        let pts = bowed(chain, side: side, by: 4.4)
        let ctx = p.ctx

        // A second, darker lock under the first, shorter and curving the same way, whose tip peels
        // away from it: the end splits like hair and doesn't look like a furled umbrella.
        let last = chain[chain.count - 1]
        let dx = last.x - chain[0].x, dy = last.y - chain[0].y
        let d = max(hypot(dx, dy), 0.01)
        var lock = Array(bowed(chain, side: side, by: 2.6)[2..<(chain.count - 1)])
        for i in lock.indices {
            let t = CGFloat(i) / CGFloat(lock.count - 1)
            lock[i].x -= dy / d * side * t * t * 2.4
            lock[i].y += dx / d * side * t * t * 2.4
        }
        if !p.halo {
            // Hair between the two locks, or the white of the halo would show through there.
            ctx.move(to: pts[2])
            for i in 3..<(pts.count - 1) { ctx.addLine(to: pts[i]) }
            for point in lock.reversed() { ctx.addLine(to: point) }
            ctx.closePath()
            ctx.setFillColor(Ink.hairDark)
            ctx.fillPath()
        }
        if let under = Kit.ribbon(lock, rootWidth: 2.9, tipWidth: 0.3, notch: 0) {
            p.shape(under, Ink.hairDark)
        }

        // Narrow at the tie, full some way past it, then a long taper to a point. A ribbon's width
        // only runs one way, so two of them meet at the fullest place, on a disc to round the join.
        let full: CGFloat = 3.8, knee = 3
        guard let near = Kit.ribbon(Array(pts[...knee]), rootWidth: 1.5, tipWidth: full, notch: 0),
              let far = Kit.ribbon(Array(pts[knee...]), rootWidth: full, tipWidth: 0.3, notch: 0) else { return }
        let join = CGPath(ellipseIn: CGRect(x: pts[knee].x - full, y: pts[knee].y - full, width: full * 2, height: full * 2),
                          transform: nil)
        // Like a limb: the outline stroked first, then the colour over it, so no seams show.
        for piece in [near, join, far] { ctx.addPath(piece) }
        ctx.setStrokeColor(p.halo ? Ink.halo : Ink.line)
        ctx.setLineWidth(p.halo ? 2.3 + 2.2 : 2.3)
        ctx.strokePath()
        guard !p.halo else { return }
        ctx.setFillColor(Ink.hair)
        for piece in [near, join, far] {
            ctx.addPath(piece)
            ctx.fillPath()
        }
        // A short shine, on the swell of it.
        let shineFrom = mid(pts[2], pts[3]), shineTo = mid(pts[4], pts[5])
        ctx.move(to: shineFrom)
        ctx.addQuadCurve(to: shineTo, control: pts[4])
        ctx.setStrokeColor(Ink.hairLight)
        ctx.setLineWidth(1.1)
        ctx.strokePath()
        // The brass tie, a band round the hair, a little way out from the hood.
        let a = pts[2], b = pts[3]
        let tx = b.x - a.x, ty = b.y - a.y
        let tl = max(hypot(tx, ty), 0.01)
        let c = CGPoint(x: a.x + tx * 0.3, y: a.y + ty * 0.3)
        let nx = -ty / tl * 2.5, ny = tx / tl * 2.5
        for (color, width) in [(Ink.line, CGFloat(3.4)), (Ink.brass, CGFloat(1.7))] {
            ctx.move(to: CGPoint(x: c.x + nx, y: c.y + ny))
            ctx.addLine(to: CGPoint(x: c.x - nx, y: c.y - ny))
            ctx.setStrokeColor(color)
            ctx.setLineWidth(width)
            ctx.strokePath()
        }
    }

    /// However fast she's going the cord droops, more toward its end and the flatter it lies.
    /// Dead straight, with a ball on the end, it looks like a rattle.
    private static func drooped(_ pts: [CGPoint], by droop: CGFloat) -> [CGPoint] {
        guard let first = pts.first, let last = pts.last, pts.count > 1 else { return pts }
        let dx = last.x - first.x, dy = last.y - first.y
        let flat = abs(dx) / max(hypot(dx, dy), 0.01)
        var out = pts
        for i in pts.indices {
            let t = CGFloat(i) / CGFloat(pts.count - 1)
            out[i].y += droop * flat * t * t
        }
        return out
    }

    private static func drawBell(_ p: Painter, _ pose: Pose) {
        guard pose.scarfB.count > 1 else { return }
        let pts = drooped(Kit.tucked(pose.scarfB, pose), by: 5)
        let ctx = p.ctx
        let cord = CGMutablePath()
        cord.move(to: pts[0])
        for i in 1..<pts.count {
            cord.addQuadCurve(to: mid(pts[i - 1], pts[i]), control: pts[i - 1])
        }
        cord.addLine(to: pts[pts.count - 1])

        ctx.addPath(cord)
        if p.halo {
            ctx.setStrokeColor(Ink.halo)
            ctx.setLineWidth(1.9 + 2.2)
            ctx.strokePath()
        } else {
            ctx.setStrokeColor(Ink.line)
            ctx.setLineWidth(1.9)
            ctx.strokePath()
            ctx.addPath(cord)
            ctx.setStrokeColor(Ink.cord)
            ctx.setLineWidth(0.8)
            ctx.strokePath()
        }

        // The sash knot sits on the cord's root, so the two can't come apart.
        p.oval(pts[0].x, pts[0].y, 2.1, 1.9, Ink.sash, line: 1)

        // The bell turns with the last link of the cord.
        let end = pts[pts.count - 1], before = pts[pts.count - 2]
        ctx.saveGState()
        ctx.translateBy(x: end.x, y: end.y)
        ctx.rotate(by: atan2(end.y - before.y, end.x - before.x) - .pi / 2)
        p.oval(0, 0.1, 1.2, 1.2, Ink.brass, line: 0.9)
        p.shape(Shape.bell, Ink.brass, line: 1.05)
        if !p.halo {
            ctx.addPath(Shape.bellShade)
            ctx.setFillColor(Ink.brassDark)
            ctx.fillPath()
            ctx.addPath(Shape.bellSlit)
            ctx.setStrokeColor(Ink.line)
            ctx.setLineWidth(1)
            ctx.strokePath()
            ctx.setFillColor(Ink.brassLight)
            ctx.fillEllipse(in: Shape.bellShine)
            ctx.addPath(Shape.bell)
            ctx.setStrokeColor(Ink.line)
            ctx.setLineWidth(1.05)
            ctx.strokePath()
        }
        ctx.restoreGState()
    }

    // MARK: Body

    /// The free arm starts at her side, and comes across her chest as she falls asleep.
    private static func freeArm(_ pose: Pose) -> (hug: CGFloat, elbow: CGPoint, hand: CGPoint) {
        let d = pose.drowse
        let hug = d * d * (3 - 2 * d)
        let rest = CGPoint(x: 12.2 + pose.armSwing * 2.5 + pose.hover * 1.4,
                           y: 11.5 - abs(pose.armSwing) * 1.2 - pose.hover * 4)
        return (hug,
                CGPoint(x: 10.5 + 1.6 * hug, y: 6.5 + 3.4 * hug),
                CGPoint(x: rest.x * (1 - hug), y: rest.y + (9.6 - rest.y) * hug))
    }

    private static let hugsFrom: CGFloat = 0.08
    private static let freeShoulder = CGPoint(x: 7.5, y: 3.5)

    private static func drawLowerBody(_ p: Painter, _ pose: Pose) {
        let ctx = p.ctx

        // Legs and split-toed socks
        let swing = pose.legSwing
        for (x, s) in [(CGFloat(-4.3), swing), (CGFloat(4.3), -swing)] {
            let foot = CGPoint(x: x + s * 2.6, y: 23.5 - abs(s) * 0.8)
            p.limb(CGPoint(x: x, y: 16.5), CGPoint(x: x, y: 20), foot, width: 3.8, Ink.leg)
            let toe = foot.x + (x < 0 ? -0.9 : 0.9)
            p.oval(toe, foot.y + 1.2, 3.5, 2.4, Ink.tabi)
            if !p.halo {
                ctx.move(to: CGPoint(x: toe + (x < 0 ? -1.4 : 1.4), y: foot.y + 0.5))
                ctx.addLine(to: CGPoint(x: toe + (x < 0 ? -1.4 : 1.4), y: foot.y + 2.2))
                ctx.setStrokeColor(Ink.line)
                ctx.setLineWidth(0.7)
                ctx.strokePath()
            }
        }

        let arm = freeArm(pose)
        if arm.hug <= hugsFrom {
            p.limb(freeShoulder, arm.elbow, arm.hand, width: 4, Ink.cloth)
            p.oval(arm.hand.x + 0.2, arm.hand.y + 0.8, 2.5, 2.5, Ink.skin, line: 1)
        }

        // Tunic
        p.shape(Shape.torso, Ink.cloth)
        if !p.halo {
            ctx.saveGState()
            ctx.addPath(Shape.torso)
            ctx.clip()
            ctx.setFillColor(Ink.clothDark)
            ctx.fill(CGRect(x: 5.2, y: -2, width: 8, height: 24))
            ctx.restoreGState()
            ctx.addPath(Shape.torso)
            ctx.setStrokeColor(Ink.line)
            ctx.setLineWidth(1.15)
            ctx.strokePath()
            // Slit in the skirt of the tunic
            ctx.setStrokeColor(Ink.clothDark)
            ctx.setLineWidth(1)
            ctx.move(to: CGPoint(x: -1.2, y: 14.5)); ctx.addLine(to: CGPoint(x: -1.6, y: 18.6))
            ctx.strokePath()
        }

        // Sash
        p.shape(Shape.sash, Ink.sash, line: 1)
        if !p.halo {
            ctx.setStrokeColor(Ink.sashDark)
            ctx.setLineWidth(0.9)
            ctx.move(to: CGPoint(x: -8.6, y: 11.2)); ctx.addQuadCurve(to: CGPoint(x: 6, y: 11.9), control: CGPoint(x: 0, y: 13))
            ctx.strokePath()
        }
    }

    /// In front of the pointing arm's shoulder, which comes out from under the cowl.
    private static func drawUpperBody(_ p: Painter, _ pose: Pose) {
        let ctx = p.ctx

        // The bottom of the hood, round the neck.
        p.shape(Shape.cowl, Ink.hood)
        if !p.halo {
            ctx.setStrokeColor(Ink.hoodDark)
            ctx.setLineWidth(1)
            ctx.move(to: CGPoint(x: -8, y: 2.2)); ctx.addQuadCurve(to: CGPoint(x: 0, y: 6.2), control: CGPoint(x: -4, y: 3.2))
            ctx.addQuadCurve(to: CGPoint(x: 8, y: 2.2), control: CGPoint(x: 4, y: 3.2))
            ctx.strokePath()
        }

        let arm = freeArm(pose)
        if arm.hug > hugsFrom {
            // She hugs it: the sleeve goes round behind the scroll, the hand holds it from the front.
            // It swings round from pointing at us, end on and hidden by her hand, so it isn't
            // conjured out of nothing as she reaches for it.
            let t = min((arm.hug - hugsFrom) / 0.42, 1)
            let swing = t * t * (3 - 2 * t)
            p.limb(freeShoulder, arm.elbow, arm.hand, width: 4, Ink.cloth)
            drawScroll(p, at: CGPoint(x: arm.hand.x, y: arm.hand.y - 0.6), length: 0.2 + 0.8 * swing)
            p.oval(arm.hand.x + 0.2, arm.hand.y + 0.8, 2.5, 2.5, Ink.skin, line: 1)
        }
    }

    private static func drawScroll(_ p: Painter, at c: CGPoint, length: CGFloat) {
        let ctx = p.ctx
        ctx.saveGState()
        ctx.translateBy(x: c.x, y: c.y)
        ctx.rotate(by: -0.5)
        ctx.scaleBy(x: length, y: 1)
        p.shape(Shape.scrollKnobs, Ink.hairDark, line: 1)
        p.shape(Shape.scrollRoll, Ink.paper, line: 1.05)
        if !p.halo {
            ctx.setFillColor(Ink.paperShade)
            ctx.fill(Shape.scrollShade)
            ctx.setFillColor(Ink.hood)
            ctx.fill(Shape.scrollBand)
            ctx.addPath(Shape.scrollRoll)
            ctx.setStrokeColor(Ink.line)
            ctx.setLineWidth(1.05)
            ctx.strokePath()
        }
        ctx.restoreGState()
    }

    // MARK: Head

    private static func drawHead(_ p: Painter, _ pose: Pose) {
        Kit.inHeadSpace(p.ctx, pose) {
            p.ctx.translateBy(x: 0, y: headDrop(pose))
            drawHeadShapes(p, pose)
        }
    }

    /// She nods off into her scroll, and perks up over a link.
    private static func headDrop(_ pose: Pose) -> CGFloat {
        pose.drowse * 1.4 - pose.hover * 0.8
    }

    private static func drawHeadShapes(_ p: Painter, _ pose: Pose) {
        let ctx = p.ctx

        // The point of the hood lies back, as cloth does. It flicks up for a moment now and then,
        // lifts to trail behind her as she goes, and droops a little further as she sleeps.
        ctx.saveGState()
        ctx.translateBy(x: 8, y: -23)
        ctx.rotate(by: max(0.5 + pose.earR * 0.7 + (pose.tailAngle + 0.75) * 0.2, 0.2) + pose.drowse * 0.3)
        p.shape(Shape.hoodTip, Ink.hood)
        if !p.halo {
            ctx.addPath(Shape.hoodTipFold)
            ctx.setStrokeColor(Ink.hoodDark)
            ctx.setLineWidth(1)
            ctx.strokePath()
        }
        ctx.restoreGState()

        p.shape(Shape.hood, Ink.hood)
        if p.halo { return }

        ctx.addPath(Shape.hoodShade)
        ctx.setFillColor(Ink.hoodDark)
        ctx.fillPath()
        ctx.addPath(Shape.hoodFolds)
        ctx.setStrokeColor(Ink.hoodDark)
        ctx.setLineWidth(1)
        ctx.strokePath()
        ctx.addPath(Shape.hood)
        ctx.setStrokeColor(Ink.line)
        ctx.setLineWidth(1.15)
        ctx.strokePath()

        // The opening slides a little with the head's turn, the face inside it a little more.
        ctx.saveGState()
        ctx.translateBy(x: pose.turn * 0.6, y: 0)
        ctx.addPath(Shape.hem)
        ctx.setStrokeColor(Ink.hoodLight)
        ctx.setLineWidth(1.5)
        ctx.strokePath()
        ctx.addPath(Shape.opening)
        ctx.setFillColor(Ink.hoodInside)
        ctx.fillPath()

        ctx.saveGState()
        ctx.addPath(Shape.opening)
        ctx.clip()
        drawFace(p, pose, features: pose.turn * 0.65)
        ctx.restoreGState()

        ctx.addPath(Shape.opening)
        ctx.setStrokeColor(Ink.line)
        ctx.setLineWidth(1.15)
        ctx.strokePath()
        ctx.restoreGState()
    }

    private static func drawFace(_ p: Painter, _ pose: Pose, features turn: CGFloat) {
        let ctx = p.ctx
        p.shape(Shape.face, Ink.skin)

        // Shadow the fringe throws on the forehead.
        ctx.saveGState()
        ctx.translateBy(x: turn * 0.4, y: 1.9)
        ctx.addPath(Shape.fringe)
        ctx.setFillColor(Ink.skinShade)
        ctx.fillPath()
        ctx.restoreGState()

        // Blush, on her cheeks and not on the inside of her hood.
        ctx.saveGState()
        ctx.addPath(Shape.face)
        ctx.clip()
        ctx.setFillColor(Ink.blush)
        for sx in [CGFloat(-1), 1] {
            ctx.fillEllipse(in: CGRect(x: sx * 9.9 + turn - 2.7, y: 8, width: 5.4, height: 2.6))
        }
        ctx.restoreGState()

        drawEyes(p, pose, turn: turn)
        drawMouth(p, pose, turn: turn)

        ctx.saveGState()
        ctx.translateBy(x: turn * 0.4, y: 0)
        p.shape(Shape.fringe, Ink.hair)
        ctx.addPath(Shape.hairShine)
        ctx.setStrokeColor(Ink.hairLight)
        ctx.setLineWidth(1.4)
        ctx.strokePath()
        ctx.restoreGState()

        drawBrows(ctx, pose, turn: turn)
    }

    private static func drawEyes(_ p: Painter, _ pose: Pose, turn: CGFloat) {
        let ctx = p.ctx
        for side in [CGFloat(-1), 1] {
            ctx.saveGState()
            ctx.translateBy(x: side * 7.2 + turn, y: 3.4)

            switch pose.expression {
            case .happy:
                Kit.arc(ctx, CGPoint(x: -4.3, y: 1.4), CGPoint(x: 0, y: -4.8), CGPoint(x: 4.3, y: 1.4), width: 1.9)
            case .asleep:
                Kit.arc(ctx, CGPoint(x: -4.3, y: -0.4), CGPoint(x: 0, y: 3.2), CGPoint(x: 4.3, y: -0.4), width: 1.8)
                Kit.arc(ctx, CGPoint(x: side * 4.1, y: -0.2), CGPoint(x: side * 5.1, y: -0.9), CGPoint(x: side * 5.7, y: -2), width: 1.1)
            case .dizzy:
                Kit.spiral(ctx, flip: side)
            case .surprised, .excited:
                ctx.scaleBy(x: 0.95, y: 0.95)
                Kit.openEye(ctx, pose, side: side, iris: Ink.iris, lash: Shape.lashWide)
            default:
                // Calm, with the lid resting low. Focused sits lower still: the Kit moves the
                // lash for that.
                let open = max(min(pose.blink, 1), 0)
                ctx.scaleBy(x: 0.95, y: 0.95)
                Kit.openEye(ctx, pose, side: side, iris: Ink.iris, lash: Shape.lash)
                if open >= 0.2 {
                    ctx.translateBy(x: 0, y: 1.4)
                    ctx.scaleBy(x: side > 0 ? 1 : -1, y: open)
                    ctx.translateBy(x: 0, y: -1.4 + (pose.expression == .focused ? 1.2 : 0))
                    ctx.addPath(Shape.lid)
                    ctx.setFillColor(Ink.skin)
                    ctx.fillPath()
                    ctx.addPath(Shape.lash)
                    ctx.setFillColor(Ink.line)
                    ctx.fillPath()
                }
            }
            ctx.restoreGState()
        }
    }

    private static func drawBrows(_ ctx: CGContext, _ pose: Pose, turn: CGFloat) {
        // Short and thin at rest. They do most of the work on a focused or startled face.
        let y: CGFloat, tilt: CGFloat, arch: CGFloat, width: CGFloat
        switch pose.expression {
        case .focused: y = -2.2; tilt = 1.4; arch = 0; width = 1.15
        case .surprised: y = -5.8; tilt = -0.5; arch = 1; width = 0.95
        case .excited: y = -5.2; tilt = -0.4; arch = 0.9; width = 0.9
        case .neutral: y = -3; tilt = 0; arch = 0.7; width = 0.8
        default: return
        }
        ctx.setStrokeColor(Ink.line)
        ctx.setLineWidth(width)
        for side in [CGFloat(-1), 1] {
            // The fringe comes lower on the pointing side, and a raised brow must stay on skin.
            let at = side < 0 ? max(y, -3.8) : y
            ctx.move(to: CGPoint(x: side * 9.8 + turn, y: at - tilt))
            ctx.addQuadCurve(to: CGPoint(x: side * 4.8 + turn, y: at + tilt),
                             control: CGPoint(x: side * 7.3 + turn, y: at - arch))
            ctx.strokePath()
        }
    }

    private static let openSmile = path {
        $0.m(-3.1, -0.8); $0.q(0, 0.2, 3.1, -0.8); $0.q(2.7, 3.4, 0, 3.5); $0.q(-2.7, 3.4, -3.1, -0.8); $0.z()
    }

    private static func drawMouth(_ p: Painter, _ pose: Pose, turn: CGFloat) {
        let ctx = p.ctx
        ctx.saveGState()
        ctx.translateBy(x: turn, y: 10.8)
        defer { ctx.restoreGState() }
        ctx.setStrokeColor(Ink.line)
        ctx.setLineWidth(0.95)

        switch pose.expression {
        case .happy, .excited:
            ctx.addPath(openSmile)
            ctx.setFillColor(Ink.mouth)
            ctx.fillPath()
            ctx.saveGState()
            ctx.addPath(openSmile)
            ctx.clip()
            ctx.setFillColor(Ink.tongue)
            ctx.fillEllipse(in: CGRect(x: -2.1, y: 1.1, width: 4.2, height: 3.2))
            ctx.restoreGState()
            ctx.addPath(openSmile)
            ctx.strokePath()
        case .surprised:
            let r = CGRect(x: -1.5, y: -1, width: 3, height: 3.4)
            ctx.setFillColor(Ink.mouth)
            ctx.fillEllipse(in: r)
            ctx.strokeEllipse(in: r)
        case .focused:
            ctx.move(to: CGPoint(x: -2, y: 0.4)); ctx.addLine(to: CGPoint(x: 2.1, y: 0.2))
            ctx.strokePath()
        case .asleep:
            ctx.move(to: CGPoint(x: -1.3, y: 0.3))
            ctx.addQuadCurve(to: CGPoint(x: 1.3, y: 0.3), control: CGPoint(x: 0, y: 1.5))
            ctx.strokePath()
        case .dizzy:
            ctx.move(to: CGPoint(x: -3, y: 0.6))
            ctx.addQuadCurve(to: CGPoint(x: -1, y: 0.4), control: CGPoint(x: -2, y: -0.8))
            ctx.addQuadCurve(to: CGPoint(x: 1, y: 0.4), control: CGPoint(x: 0, y: 1.7))
            ctx.addQuadCurve(to: CGPoint(x: 3, y: 0.4), control: CGPoint(x: 2, y: -0.8))
            ctx.strokePath()
        case .neutral:
            // A small confident smile, higher on one side.
            ctx.move(to: CGPoint(x: -2.5, y: 0))
            ctx.addQuadCurve(to: CGPoint(x: 2.9, y: -0.8), control: CGPoint(x: 0.3, y: 1.9))
            ctx.strokePath()
        }
    }

    // MARK: Smoke and paper

    private static func drawPuffs(_ ctx: CGContext, _ pose: Pose, clearSpace: Bool) {
        guard pose.puffs.contains(where: { $0.alpha > 0.01 }) else { return }
        ctx.saveGState()
        // A little clear space around the hotspot: wherever the smoke goes, the click point shows.
        // Hardly bigger than the arm's own white edge, so that it doesn't show as a hole.
        if clearSpace {
            cutOut(ctx) { ctx.addEllipse(in: CGRect(x: -3.6, y: -3.6, width: 7.2, height: 7.2)) }
        }

        // All the edges first, then all the fills, so that a cluster of puffs reads as one
        // cloud with one outline instead of a heap of circles. The edges fade ahead of the fill.
        for pass in 0..<4 {
            for puff in pose.puffs where puff.alpha > 0.01 {
                drawCloud(ctx, puff, pass: pass)
            }
        }
        ctx.restoreGState()
    }

    private static func drawCloud(_ ctx: CGContext, _ puff: Puff, pass: Int) {
        let alpha = puff.alpha
        // Edges and shade that have all but faded aren't worth the time.
        if (pass == 0 && alpha < 0.4) || (pass < 3 && alpha < 0.12) { return }
        // Thinning smoke draws in a little, so that the puffs come apart and don't lie in a heap.
        let r = puff.radius * (0.72 + 0.28 * alpha)
        // Which way its lobes point, and which of the shapes it is.
        let turn = puff.turn
        let shape = Shape.clouds[Int((turn + .pi) * 2.2) % Shape.clouds.count]
        ctx.saveGState()
        switch pass {
        case 0: ctx.setAlpha(alpha * alpha * alpha * alpha)
        case 3: ctx.setAlpha(alpha)
        default: ctx.setAlpha(alpha * alpha)
        }
        if pass == 3 {
            // The lit part sits up and to the left of its shade. As the smoke thins it spreads to
            // cover the shade, which would otherwise show through as a ring.
            let lit = max(1 - (1 - alpha) * 2.5, 0)
            ctx.translateBy(x: puff.pos.x - r * 0.07 * lit, y: puff.pos.y - r * 0.09 * lit)
            ctx.rotate(by: turn)
            let k = r * (1 - 0.12 * lit)
            ctx.scaleBy(x: k, y: k)
        } else {
            ctx.translateBy(x: puff.pos.x, y: puff.pos.y)
            ctx.rotate(by: turn)
            ctx.scaleBy(x: r, y: r)
        }
        ctx.addPath(shape)
        switch pass {
        case 0:
            ctx.setStrokeColor(Ink.halo)
            ctx.setLineWidth((1.8 + 2.2) / r)
            ctx.strokePath()
        case 1:
            ctx.setStrokeColor(Ink.line)
            ctx.setLineWidth(1.8 / r)
            ctx.strokePath()
        case 2:
            ctx.setFillColor(Ink.smokeShade)
            ctx.fillPath()
        default:
            ctx.setFillColor(Ink.smoke)
            ctx.fillPath()
        }
        ctx.restoreGState()
    }

    /// While she's gone, a wisp over the shoulder, so the arm comes out of the cloud and doesn't
    /// hang in front of it with its end showing. No outline: it melts into the cloud behind it.
    private static func drawShoulderPuff(_ ctx: CGContext, _ pose: Pose) {
        guard pose.vanish > 0.01 else { return }
        let thickest = pose.puffs.reduce(CGFloat(0)) { max($0, $1.alpha) }
        guard thickest > 0.01 else { return }
        let at = shoulder(pose)
        let r: CGFloat = 8
        guard hypot(at.x, at.y) > r + 8 else { return }
        let puff = Puff(pos: at, radius: r, alpha: thickest * min(pose.vanish * 2.5, 1))
        drawCloud(ctx, puff, pass: 2)
        drawCloud(ctx, puff, pass: 3)
    }

    private static func drawShuriken(_ ctx: CGContext, _ pose: Pose) {
        for s in pose.sparkles where s.alpha > 0.01 {
            let k = s.size * 1.2
            ctx.saveGState()
            ctx.setAlpha(s.alpha)
            ctx.translateBy(x: s.pos.x, y: s.pos.y)
            ctx.rotate(by: s.rot)
            ctx.scaleBy(x: k, y: k)
            ctx.addPath(Shape.shuriken)
            ctx.setStrokeColor(Ink.halo)
            ctx.setLineWidth(2.6 / k)
            ctx.strokePath()
            ctx.addPath(Shape.shuriken)
            ctx.setFillColor(Ink.paper)
            ctx.fillPath()
            ctx.addPath(Shape.shurikenFold)
            ctx.setFillColor(Ink.hood)
            ctx.fillPath()
            ctx.addPath(Shape.shuriken)
            ctx.setStrokeColor(Ink.line)
            ctx.setLineWidth(0.85 / k)
            ctx.strokePath()
            ctx.restoreGState()
        }
    }
}
