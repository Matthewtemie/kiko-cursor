import CoreGraphics

extension Motion {
    /// Heavy and rolling, as if on waves: the two chains are the tails of the coat, one
    /// either side of the vent at the back of the waist.
    static let marlo = Motion(
        omega: 10.5, zeta: 0.62,
        bobSize: 2.4, bobRate: 1.6,
        rollSize: 0.055, rollRate: 1.1,
        chainA: ChainSpec(nodes: 5, seg: 3.7, anchor: CGPoint(x: 7.5, y: 13), pull: CGPoint(x: 60, y: 260),
                          breeze: 0.4, flutter: 0.35, phase: 0, followsBody: true),
        chainB: ChainSpec(nodes: 5, seg: 3.7, anchor: CGPoint(x: -7.5, y: 13), pull: CGPoint(x: -60, y: 260),
                          breeze: -0.4, flutter: 0.35, phase: 1.7, followsBody: true),
        burst: Burst(count: 7, speed: 40...95, life: 0.5...0.62, size: 2.8...3.8, spin: 16, drag: 0.5,
                     gravity: 760, lift: 170, shrink: 0))
}

private enum Ink {
    static let line = Line.ink
    static let skin = rgb(0xB5764C)
    static let skinShade = rgb(0x955A38)
    static let hair = rgb(0xD0672B)
    static let hairDark = rgb(0x97451F)
    static let hairLight = rgb(0xF29A58)
    static let brow = rgb(0x4E2410)
    static let navy = rgb(0x2A4288)
    static let navyDark = rgb(0x1C2D62)
    static let gold = rgb(0xF2C23E)
    static let goldDark = rgb(0xB5821F)
    static let goldLight = rgb(0xFFE89A)
    static let feather = rgb(0xE5303A)
    static let featherDark = rgb(0xA81B2A)
    static let coat = rgb(0x2F7A4E)
    static let coatDark = rgb(0x205838)
    static let cream = rgb(0xF7EDD6)
    static let boot = rgb(0x7A4C28)
    static let leather = rgb(0x6B3F1E)
    static let glass = rgb(0xC4ECF8)
    static let scarlet = rgb(0xE3242F)
    static let scarletDark = rgb(0xAE1826)
    static let wing = rgb(0x2F6FD6)
    static let wingDark = rgb(0x1F4CA0)
    static let patch = rgb(0xFFD52E)
    static let beak = rgb(0xFFC23A)
    static let blush = rgb(0xE9503F, 0.42)
    static let mouth = rgb(0x6E1D2C)
    static let tongue = rgb(0xF4737F)
    static let white = Line.white
    static let iris = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                                 colors: [rgb(0x6A3F10), rgb(0xC9921F), rgb(0xA9DE57)] as CFArray,
                                 locations: [0, 0.55, 1])!
}

private func oval(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> CGPath {
    CGPath(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2), transform: nil)
}

private func mix(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }

private func mix(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
    CGPoint(x: mix(a.x, b.x, t), y: mix(a.y, b.y, t))
}

private func smooth(_ t: CGFloat) -> CGFloat {
    let c = min(max(t, 0), 1)
    return c * c * (3 - 2 * c)
}

/// Fixed outlines, built once. Head shapes are centred on the head; everything is in points.
private enum Shape {
    // Head
    static let face = path {
        $0.m(-16, -3); $0.c(-16, -14, -8, -18, 0, -18); $0.c(8, -18, 16, -14, 16, -3)
        $0.c(16, 7, 9, 14, 0, 15.5); $0.c(-9, 14, -16, 7, -16, -3); $0.z()
    }
    static let hairBack = path {
        $0.m(-13, -15); $0.q(-22.5, -17, -21, -9); $0.q(-25.5, -5, -21.5, -1)
        $0.q(-25, 4, -19.5, 6); $0.q(-19.5, 11.5, -13.5, 9.5); $0.l(13.5, 9.5)
        $0.q(19.5, 11.5, 19.5, 6); $0.q(25, 4, 21.5, -1); $0.q(25.5, -5, 21, -9)
        $0.q(22.5, -17, 13, -15); $0.z()
    }
    static let fringe = path {
        $0.m(-16.5, -14); $0.l(16.5, -14); $0.q(18, -10.5, 15, -9.4)
        $0.q(12.6, -6.8, 9.6, -9.2); $0.q(7, -6.8, 4.2, -9.4); $0.q(1.2, -6.6, -1.4, -9.4)
        $0.q(-4, -6.8, -6.8, -9.2); $0.q(-9.4, -6.6, -11.8, -9.2); $0.q(-14, -7, -15.2, -9.4)
        $0.q(-18, -10.5, -16.5, -14); $0.z()
    }
    static let fringeShade = path {
        $0.m(-14.6, -10.8); $0.l(14.6, -10.8); $0.q(12.6, -5.8, 9.6, -8.2)
        $0.q(7, -5.8, 4.2, -8.4); $0.q(1.2, -5.6, -1.4, -8.4)
        $0.q(-4, -5.8, -6.8, -8.2); $0.q(-9.4, -5.6, -11.8, -8.2); $0.q(-13.6, -6, -14.6, -10.8); $0.z()
    }
    static let curls = path {
        $0.m(-16, -11); $0.q(-20, -7.5, -17, -4.6); $0.q(-19.8, -1, -16.8, 1.2)
        $0.q(-18.6, 5.6, -14.4, 5.4); $0.q(-12.4, 3.8, -13.6, 0.8); $0.q(-12, -3, -13.4, -5); $0.q(-12.6, -8.6, -13.5, -11); $0.z()
        $0.m(16, -11); $0.q(20, -7.5, 17, -4.6); $0.q(19.8, -1, 16.8, 1.2)
        $0.q(18.6, 5.6, 14.4, 5.4); $0.q(12.4, 3.8, 13.6, 0.8); $0.q(12, -3, 13.4, -5); $0.q(12.6, -8.6, 13.5, -11); $0.z()
    }
    static let hairShine = path {
        $0.m(-20, -8); $0.q(-22.2, -5.4, -20.2, -3.2); $0.m(-20.4, 0.2); $0.q(-22.4, 3, -19.6, 4.6)
        $0.m(20, -8); $0.q(22.2, -5.4, 20.2, -3.2); $0.m(20.4, 0.2); $0.q(22.4, 3, 19.6, 4.6)
    }
    static let lash = path {
        $0.m(-5.3, -2.8); $0.q(-4.8, -6.4, 0, -6.8); $0.q(4.8, -6.4, 5.3, -2.8)
        $0.q(3.8, -5, 0, -5.2); $0.q(-3.8, -5, -5.3, -2.8); $0.z()
    }

    // Mouth
    static let grin = path {
        $0.m(-9, 6); $0.q(0, 8.6, 9, 6); $0.c(8.9, 11, 5, 13.9, 0, 13.9); $0.c(-5, 13.9, -8.9, 11, -9, 6); $0.z()
    }
    static let teeth = path {
        $0.m(-8.1, 6.6); $0.q(0, 9, 8.1, 6.6); $0.q(7.6, 8.8, 6.5, 9.4); $0.q(0, 11.3, -6.5, 9.4); $0.q(-7.6, 8.8, -8.1, 6.6); $0.z()
    }
    static let tongue = path {
        $0.m(-4.5, 12.7); $0.q(0, 9.6, 4.5, 12.7); $0.q(2.4, 13.8, 0, 13.8); $0.q(-2.4, 13.8, -4.5, 12.7); $0.z()
    }
    static let gasp = oval(0, 11.7, 2.3, 2.6)
    static let gaspTongue = path {
        $0.m(-1.9, 12.9); $0.q(0, 11.5, 1.9, 12.9); $0.q(1.1, 14.2, 0, 14.2); $0.q(-1.1, 14.2, -1.9, 12.9); $0.z()
    }

    // Hat
    static let crown = path {
        $0.m(-14, -15); $0.c(-14.5, -27, -8, -34, 0, -34); $0.c(8, -34, 14.5, -27, 14, -15); $0.z()
    }
    static let brim = path {
        $0.m(-25, -22); $0.q(-18.5, -20.5, -13, -23.5); $0.q(-6.5, -27.5, 0, -28.5)
        $0.q(6.5, -27.5, 13, -23.5); $0.q(18.5, -20.5, 25, -22)
        $0.q(23, -14, 15, -11.5); $0.q(7, -9.4, 0, -7.6); $0.q(-7, -9.4, -15, -11.5); $0.q(-23, -14, -25, -22); $0.z()
    }
    static let trim = path {
        $0.m(-22.4, -20.3); $0.q(-17.5, -19.6, -12.4, -22); $0.q(-6.4, -25.6, 0, -26.6)
        $0.q(6.4, -25.6, 12.4, -22); $0.q(17.5, -19.6, 22.4, -20.3)
    }
    static let brimShade = path {
        $0.m(-20.8, -15.2); $0.q(-17, -11.6, -15, -11.9); $0.q(-7, -9.8, 0, -8)
        $0.q(7, -9.8, 15, -11.9); $0.q(17, -11.6, 20.8, -15.2); $0.q(10, -11.5, 0, -11.3); $0.q(-10, -11.5, -20.8, -15.2); $0.z()
    }
    static let feather = path {
        $0.m(1, 1); $0.c(-2, -7, -9, -12, -17.5, -12.5); $0.c(-16, -9, -14.4, -7.6, -13, -6.4)
        $0.l(-10.6, -6.8); $0.c(-8.6, -3.8, -5, -1.2, -1, 1.6); $0.z()
    }
    static let featherSpine = path { $0.m(0, 0.6); $0.c(-3.6, -4.6, -9, -8.4, -14, -10) }

    // Body
    static let torso = path {
        $0.m(-8, -1.5); $0.c(-10.5, 4, -11.5, 11, -11, 17.5); $0.q(0, 20.5, 11, 17.5)
        $0.c(11.5, 11, 10.5, 4, 8, -1.5); $0.z()
    }
    static let torsoShade = path {
        $0.m(5.4, -1); $0.l(7.6, -1); $0.c(10, 4, 11, 11, 10.5, 17.2); $0.q(8.5, 18, 6.2, 18.4); $0.q(7.4, 8, 5.4, -1); $0.z()
    }
    static let cravat = path {
        $0.m(-4.2, -1); $0.q(0, 0.4, 4.2, -1); $0.q(5, 2.2, 2.8, 3.1); $0.q(3.2, 5.4, 0, 7)
        $0.q(-3.2, 5.4, -2.8, 3.1); $0.q(-5, 2.2, -4.2, -1); $0.z()
    }
    static let lapels = path {
        $0.m(-6.2, -0.6); $0.l(-0.4, 7.6); $0.m(6.2, -0.6); $0.l(0.4, 7.6)
    }
    static let hem = path { $0.m(-10.8, 15.4); $0.q(0, 18.4, 10.8, 15.4) }
    static let buttons: CGPath = {
        let b = CGMutablePath()
        for y in [CGFloat(8.8), 12, 15.2] {
            for x in [CGFloat(-3), 3] {
                b.addEllipse(in: CGRect(x: x - 1.25, y: y - 1.25, width: 2.5, height: 2.5))
            }
        }
        return b
    }()

    // Spyglass: origin at the eyepiece, looking along +x.
    static let tube = path {
        $0.m(0, -3.1); $0.l(5, -3.1); $0.l(5, -3.7); $0.l(12, -3.7); $0.l(12, -4.5); $0.l(22, -4.8)
        $0.l(22, 4.8); $0.l(12, 4.5); $0.l(12, 3.7); $0.l(5, 3.7); $0.l(5, 3.1); $0.l(0, 3.1)
        $0.q(-1.2, 0, 0, -3.1); $0.z()
    }
    static let tubeWrap = path {
        $0.m(5.5, -3.2); $0.l(11.5, -3.2); $0.l(11.5, 3.2); $0.l(5.5, 3.2); $0.z()
    }
    static let tubeShade = path {
        $0.m(12.6, 1.6); $0.l(21.5, 1.6); $0.l(21.5, 4.2); $0.l(12.6, 4); $0.z()
    }
    static let tubeShine = path {
        $0.m(13.4, -2.6); $0.l(19.6, -2.8); $0.m(1, -1.7); $0.l(4.2, -1.7)
    }
    static let tubeBand = path {
        $0.m(16.8, -4.6); $0.l(16.8, 4.6)
    }
    static let lens = oval(22, 0, 1.6, 4.8)

    // Parrot: origin at its feet, facing +x, standing with its head up.
    static let parrotTail = path {
        $0.m(-3.4, -3); $0.q(-5, 1, -5.6, 5.4); $0.l(-3.8, 4.8); $0.l(-3, 6.6); $0.q(-1, 3, 0.6, -1); $0.z()
    }
    static let parrotBody = oval(0.4, -5.4, 4.7, 5.7)
    static let parrotClaws = path {
        $0.m(-1.5, -0.8); $0.l(-1.8, 1); $0.m(1.5, -0.8); $0.l(1.7, 1)
    }
    // Head: origin at the neck.
    static let parrotHead = oval(0.4, -3.6, 4.4, 4.4)
    static let parrotCheek = oval(1.7, -4, 2, 2)
    static let parrotCrest = path {
        $0.m(-2.6, -6.4); $0.q(-4, -8.8, -2.8, -10.2); $0.q(-2, -9, -1.2, -8.6); $0.q(-0.8, -10, 0.7, -10.8)
        $0.q(1.1, -9, 1.2, -7.4); $0.z()
    }
    static let beakUpper = path {
        $0.m(3.8, -6.6); $0.c(7.4, -7.2, 9, -3.6, 7.4, -0.6); $0.q(6.4, -2.6, 4.2, -2.4); $0.z()
    }
    static let beakLower = path {
        $0.m(4.2, -2.6); $0.q(6, -2.4, 6.3, -1.2); $0.q(5.4, 0, 3.6, -0.6); $0.z()
    }
    // Wing: origin at its shoulder, hanging straight down.
    static let wing = path {
        $0.m(-3.1, -0.8); $0.c(-4.8, 2, -4.4, 6.2, -1.6, 9.2); $0.c(1.8, 6.8, 3.6, 2, 3, -0.8); $0.q(0, -2.4, -3.1, -0.8); $0.z()
    }
    static let wingTip = path {
        $0.m(-3.2, 4.2); $0.q(-0.6, 6.2, 1.8, 4.2)
    }
    static let wingPatch = oval(-0.1, 0.5, 2.3, 1.5)
}

/// Marlo, a cheerful young pirate: navy tricorn, forest-green coat, copper curls, and a
/// parrot with opinions.
enum MarloArt {
    static func draw(_ pose: Pose, in ctx: CGContext) {
        for halo in [true, false] {
            let p = Painter(ctx: ctx, halo: halo)
            drawCoatTail(p, Kit.tucked(pose.scarfB, pose))
            drawCoatTail(p, Kit.tucked(pose.scarfA, pose))
            Kit.inBodySpace(ctx, pose) {
                Kit.inHeadSpace(ctx, pose) { drawFeather(p, pose) }
                drawLowerBody(p, pose)
            }
            Kit.pointingArm(p, pose, sleeve: Ink.coat, cuff: Ink.gold, skin: Ink.skin)
            Kit.inBodySpace(ctx, pose) {
                if !halo { blendSleeve(ctx, pose) }
                Kit.inHeadSpace(ctx, pose) { drawHead(p, pose) }
                drawFreeArm(p, pose)
                drawParrot(p, pose)
            }
        }
        drawCoins(ctx, pose)
        drawZees(ctx, pose)
        Kit.handOnTop(ctx, pose, skin: Ink.skin)
    }

    /// The Zs rise from the top of the tipped hat, or they'd be born on top of the feather.
    private static func drawZees(_ ctx: CGContext, _ pose: Pose) {
        guard !pose.zees.isEmpty else { return }
        let sign: CGFloat = pose.facing < 0 ? -1 : 1
        var moved = pose
        for i in moved.zees.indices { moved.zees[i].pos.x += sign * 8 }
        Kit.zees(ctx, moved, color: Ink.navy)
    }

    /// The pointing sleeve is a round-ended tube, and its end shows on the chest. This paints
    /// that end out in the coat colour, so the sleeve grows out of the coat instead.
    private static func blendSleeve(_ ctx: CGContext, _ pose: Pose) {
        let sign: CGFloat = pose.facing < 0 ? -1 : 1
        let c = cos(pose.lean), s = sin(pose.lean)
        let shoulder = CGPoint(x: -7.8, y: 3.5)
        // The fingertip in body space, ignoring squash, which is too small to matter here.
        let tx = pose.fingerTip.x - pose.body.x, ty = pose.fingerTip.y - pose.body.y - pose.bob
        let dx = (tx * c + ty * s) * sign - shoulder.x, dy = -tx * s + ty * c - shoulder.y
        let d = max(hypot(dx, dy), 0.01)
        let ux = dx / d, uy = dy / d
        // Which way the sleeve leaves the shoulder, from how Kit.pointingArm bends it.
        let along = max(d - 7.6 * max(pose.reach, 0.25) - 2.6, 0) / 2
        let sag = max(0, 11 - d * 0.14)
        let ax = ux * along - uy * sag, ay = uy * along + ux * sag
        let a = max(hypot(ax, ay), 0.01)
        // Only while that end lies on the chest. Past the edge of the coat it would be painting
        // on the silhouette, so there the end just shows.
        let r = 3.1 * smooth((-ax / a + 0.05) / 0.3)
        guard r > 0.3 else { return }
        let patch = CGRect(x: shoulder.x + 0.3 - ax / a * 1.5 - r, y: shoulder.y - ay / a * 1.5 - r, width: r * 2, height: r * 2)
        ctx.setFillColor(Ink.coat)
        ctx.fillEllipse(in: patch)
        // That's the coat colour over the lapel and the cravat too, so they go back on top.
        ctx.saveGState()
        ctx.addEllipse(in: patch)
        ctx.clip()
        drawLapels(ctx)
        ctx.restoreGState()
    }

    /// Where a point in head space lands in body space, for things that follow the head
    /// but are drawn outside it.
    private static func headPoint(_ x: CGFloat, _ y: CGFloat, _ pose: Pose) -> CGPoint {
        let c = cos(pose.headTilt), s = sin(pose.headTilt)
        let yy = y - 14.5
        return CGPoint(x: x * c - yy * s, y: x * s + yy * c - 1)
    }

    /// How far the spyglass has come up, 0 at his side and 1 at his eye.
    private static func raised(_ pose: Pose) -> CGFloat { smooth(pose.hover) }

    private static let eyeX: CGFloat = 6.5
    private static let eyeY: CGFloat = 4.5

    // MARK: Coat

    private static func drawCoatTail(_ p: Painter, _ pts: [CGPoint]) {
        // A negative notch brings the end to a soft point, the cut of a coat tail.
        guard let ribbon = Kit.ribbon(pts, rootWidth: 2.8, tipWidth: 2.7, notch: -2.4) else { return }
        p.shape(ribbon, Ink.coat)
        guard !p.halo, pts.count > 1 else { return }
        // A gold edge across the bottom of the tail.
        let a = pts[pts.count - 2], b = pts[pts.count - 1]
        let d = max(hypot(b.x - a.x, b.y - a.y), 0.01)
        let ux = (b.x - a.x) / d, uy = (b.y - a.y) / d
        let c = CGPoint(x: b.x - ux * 0.9, y: b.y - uy * 0.9)
        p.ctx.setStrokeColor(Ink.gold)
        p.ctx.setLineWidth(1.1)
        p.ctx.move(to: CGPoint(x: c.x - uy * 2, y: c.y + ux * 2))
        p.ctx.addLine(to: CGPoint(x: c.x + uy * 2, y: c.y - ux * 2))
        p.ctx.strokePath()
    }

    private static func drawLowerBody(_ p: Painter, _ pose: Pose) {
        let ctx = p.ctx

        // Boots
        let swing = pose.legSwing
        for (x, s) in [(CGFloat(-4.3), swing), (CGFloat(4.3), -swing)] {
            let foot = CGPoint(x: x + s * 2.6, y: 23.5 - abs(s) * 0.8)
            p.limb(CGPoint(x: x, y: 16.5), CGPoint(x: x, y: 20), foot, width: 4, Ink.boot)
            p.oval(foot.x + (x < 0 ? -0.9 : 0.9), foot.y + 1.2, 3.7, 2.5, Ink.boot)
        }

        // Coat
        p.shape(Shape.torso, Ink.coat)
        guard !p.halo else { return }
        ctx.addPath(Shape.torsoShade)
        ctx.setFillColor(Ink.coatDark)
        ctx.fillPath()

        ctx.setStrokeColor(Ink.coatDark)
        ctx.setLineWidth(1)
        ctx.move(to: CGPoint(x: 0, y: 7.5)); ctx.addLine(to: CGPoint(x: 0, y: 18.6))
        ctx.strokePath()

        ctx.addPath(Shape.hem)
        ctx.setStrokeColor(Ink.gold)
        ctx.setLineWidth(1.2)
        ctx.strokePath()

        drawLapels(ctx)

        ctx.addPath(Shape.buttons)
        ctx.setFillColor(Ink.gold)
        ctx.setStrokeColor(Ink.line)
        ctx.setLineWidth(0.6)
        ctx.drawPath(using: .fillStroke)
    }

    private static func drawLapels(_ ctx: CGContext) {
        ctx.addPath(Shape.lapels)
        ctx.setStrokeColor(Ink.gold)
        ctx.setLineWidth(1)
        ctx.strokePath()

        ctx.addPath(Shape.cravat)
        ctx.setFillColor(Ink.cream)
        ctx.setStrokeColor(Ink.line)
        ctx.setLineWidth(0.9)
        ctx.drawPath(using: .fillStroke)
    }

    // MARK: Free arm and spyglass

    private static func drawFreeArm(_ p: Painter, _ pose: Pose) {
        let ctx = p.ctx
        let up = raised(pose)
        let shoulder = CGPoint(x: 8.2, y: 3.4)
        let restHand = CGPoint(x: 13 + pose.armSwing * 2.5, y: 12 - abs(pose.armSwing) * 1.2)

        var hand = restHand
        var elbow = CGPoint(x: 12.5, y: 6)
        var tube: (origin: CGPoint, angle: CGFloat, ext: CGFloat)?

        if pose.hover > 0.08 {
            // The eyepiece homes in on the eye; any overshoot just tips the far end up.
            let turn = pose.turn * 1.25
            let eye = headPoint(eyeX + turn - 3.2, eyeY - 0.4, pose)
            let origin = mix(restHand, eye, up)
            let aim = -0.24 + pose.headTilt - max(pose.hover - 1, 0) * 0.9
            let angle = mix(1.3, aim, up)
            let ext = smooth(pose.hover * 1.5)
            let grip = CGPoint(x: 9.5 * ext, y: 3.6)
            let c = cos(angle), s = sin(angle)
            let held = CGPoint(x: origin.x + grip.x * c - grip.y * s, y: origin.y + grip.x * s + grip.y * c)
            hand = mix(restHand, held, smooth(pose.hover * 2))
            elbow = mix(elbow, CGPoint(x: 21, y: 4), up)
            tube = (origin, angle, ext)
        }

        p.limb(shoulder, elbow, hand, width: 4, Ink.coat)
        if !p.halo {
            // Gold cuff across the sleeve, just short of the hand.
            let dx = hand.x - elbow.x, dy = hand.y - elbow.y
            let d = max(hypot(dx, dy), 0.01)
            let ux = dx / d, uy = dy / d
            let c = CGPoint(x: hand.x - ux * 3.2, y: hand.y - uy * 3.2)
            ctx.setStrokeColor(Ink.gold)
            ctx.setLineWidth(1.3)
            ctx.move(to: CGPoint(x: c.x - uy * 2.3, y: c.y + ux * 2.3))
            ctx.addLine(to: CGPoint(x: c.x + uy * 2.3, y: c.y - ux * 2.3))
            ctx.strokePath()
        }
        if let tube { drawSpyglass(p, tube.origin, tube.angle, tube.ext) }
        p.oval(hand.x, hand.y, 2.7, 2.7, Ink.skin, line: 1)
    }

    private static func drawSpyglass(_ p: Painter, _ origin: CGPoint, _ angle: CGFloat, _ ext: CGFloat) {
        let ctx = p.ctx
        ctx.saveGState()
        ctx.translateBy(x: origin.x, y: origin.y)
        ctx.rotate(by: angle)
        ctx.scaleBy(x: max(ext, 0.05), y: 0.6 + 0.4 * ext)
        p.shape(Shape.tube, Ink.gold)
        if !p.halo {
            ctx.addPath(Shape.tubeShade)
            ctx.setFillColor(Ink.goldDark)
            ctx.fillPath()
            ctx.addPath(Shape.tubeWrap)
            ctx.setFillColor(Ink.leather)
            ctx.fillPath()
            ctx.addPath(Shape.tubeShine)
            ctx.setStrokeColor(Ink.goldLight)
            ctx.setLineWidth(1)
            ctx.strokePath()
            ctx.addPath(Shape.tubeBand)
            ctx.setStrokeColor(Ink.line)
            ctx.setLineWidth(0.8)
            ctx.strokePath()
        }
        p.shape(Shape.lens, Ink.glass, line: 1)
        ctx.restoreGState()
    }

    // MARK: Head

    private static func drawHead(_ p: Painter, _ pose: Pose) {
        let ctx = p.ctx
        let turn = pose.turn * 1.25
        let hop: CGFloat = pose.expression == .surprised ? hatHop : 0

        // The hat coming down presses the curls down with it, or they'd show above the brim.
        ctx.saveGState()
        ctx.translateBy(x: 0, y: 9.5)
        ctx.scaleBy(x: 1, y: 1 - pose.drowse * 0.4)
        ctx.translateBy(x: 0, y: -9.5)
        p.shape(Shape.hairBack, Ink.hairDark)
        if !p.halo {
            ctx.addPath(Shape.hairShine)
            ctx.setStrokeColor(Ink.hair)
            ctx.setLineWidth(1)
            ctx.strokePath()
        }
        ctx.restoreGState()
        // The skull squashes under the hat from the chin up, or it would show over the crown.
        ctx.saveGState()
        ctx.translateBy(x: 0, y: 15.5)
        ctx.scaleBy(x: 1, y: 1 - pose.drowse * 0.14)
        ctx.translateBy(x: 0, y: -15.5)
        p.shape(Shape.face, Ink.skin)
        ctx.restoreGState()

        if !p.halo {
            // Shadow the fringe throws on the forehead.
            ctx.saveGState()
            ctx.translateBy(x: turn * 0.4, y: -hop)
            ctx.addPath(Shape.fringeShade)
            ctx.setFillColor(Ink.skinShade)
            ctx.fillPath()
            ctx.restoreGState()

            for sx in [CGFloat(-1), 1] {
                ctx.setFillColor(Ink.blush)
                ctx.fillEllipse(in: CGRect(x: sx * 9 + turn - 2.5, y: 7.6, width: 5, height: 2.4))
            }

            drawEyes(ctx, pose, turn: turn)
            drawMouth(ctx, pose, turn: turn)

            // Earring, on the side the parrot isn't.
            ctx.setStrokeColor(Ink.gold)
            ctx.setLineWidth(1)
            ctx.strokeEllipse(in: CGRect(x: -17.4, y: 6.4, width: 3.2, height: 3.6))
        }

        if !p.halo {
            ctx.saveGState()
            ctx.translateBy(x: 0, y: pose.drowse * 3.5)
            p.shape(Shape.curls, Ink.hair, line: 1)
            ctx.restoreGState()
            ctx.saveGState()
            ctx.translateBy(x: turn * 0.4, y: pose.drowse * 9 - hop)
            p.shape(Shape.fringe, Ink.hair, line: 1)
            ctx.restoreGState()
            drawBrows(ctx, pose, turn: turn)
        }

        drawHat(p, pose, turn: turn)
    }

    private static func drawEyes(_ ctx: CGContext, _ pose: Pose, turn: CGFloat) {
        let up = raised(pose)
        for side in [CGFloat(-1), 1] {
            // Behind the eyepiece there is nothing to draw.
            if side > 0 && up > 0.92 { continue }
            ctx.saveGState()
            // Wide-eyed and grinning at once: the eyes move up to make room for the mouth.
            let excited = pose.expression == .excited
            ctx.translateBy(x: side * eyeX + turn, y: eyeY - (excited ? 1.2 : 0))
            ctx.scaleBy(x: 0.93, y: excited ? 0.84 : 0.93)

            if side < 0 && up > 0.4 {
                // Screwed shut, so the other one can see.
                ctx.setStrokeColor(Ink.line)
                ctx.setLineWidth(2)
                ctx.move(to: CGPoint(x: -4.4, y: -3.2))
                ctx.addLine(to: CGPoint(x: 3.6, y: 0.2))
                ctx.addLine(to: CGPoint(x: -4.4, y: 3.2))
                ctx.strokePath()
            } else {
                switch pose.expression {
                case .happy:
                    Kit.arc(ctx, CGPoint(x: -4.8, y: -1), CGPoint(x: 0, y: -8), CGPoint(x: 4.8, y: -1), width: 2.1)
                case .asleep:
                    Kit.arc(ctx, CGPoint(x: -4.6, y: 0.2), CGPoint(x: 0, y: 3.8), CGPoint(x: 4.6, y: 0.2), width: 1.8)
                case .dizzy:
                    Kit.spiral(ctx, flip: side)
                default:
                    Kit.openEye(ctx, pose, side: side, iris: Ink.iris, lash: Shape.lash)
                }
            }
            ctx.restoreGState()
        }
    }

    private static func drawBrows(_ ctx: CGContext, _ pose: Pose, turn: CGFloat) {
        let up = raised(pose)
        ctx.setStrokeColor(Ink.brow)
        ctx.setLineWidth(2.2)
        for side in [CGFloat(-1), 1] {
            // Inner and outer ends, and how much the middle arches.
            var inner: CGFloat, outer: CGFloat, arch: CGFloat
            switch pose.expression {
            case .neutral: (inner, outer, arch) = (-4.4, -4.6, -0.8)
            case .happy, .excited: (inner, outer, arch) = (-5.4, -5.2, -0.6)
            case .surprised: (inner, outer, arch) = (-7, -6.4, -1)
            case .focused: (inner, outer, arch) = (-1.6, -5, 0)
            case .asleep: (inner, outer, arch) = (-3.6, -3.2, -0.3)
            case .dizzy: (inner, outer, arch) = side < 0 ? (-3, -5.6, 0.6) : (-5.8, -3.4, 0.6)
            }
            if up > 0 {
                let pressed: (CGFloat, CGFloat, CGFloat) = side < 0 ? (-1.6, -2.2, 0) : (-5.6, -5.2, -0.8)
                inner = mix(inner, pressed.0, up)
                outer = mix(outer, pressed.1, up)
                arch = mix(arch, pressed.2, up)
            }
            let a = CGPoint(x: side * 2.7 + turn, y: inner)
            let b = CGPoint(x: side * 10.6 + turn, y: outer)
            ctx.move(to: a)
            ctx.addQuadCurve(to: b, control: CGPoint(x: (a.x + b.x) / 2, y: (inner + outer) / 2 + arch))
            ctx.strokePath()
        }
    }

    private static func drawMouth(_ ctx: CGContext, _ pose: Pose, turn: CGFloat) {
        ctx.saveGState()
        ctx.translateBy(x: turn, y: 0)
        defer { ctx.restoreGState() }
        ctx.setStrokeColor(Ink.line)
        ctx.setLineWidth(1.05)

        switch pose.expression {
        case .happy, .excited:
            // The grin that takes up half his face.
            ctx.addPath(Shape.grin)
            ctx.setFillColor(Ink.mouth)
            ctx.fillPath()
            ctx.addPath(Shape.tongue)
            ctx.setFillColor(Ink.tongue)
            ctx.fillPath()
            ctx.addPath(Shape.teeth)
            ctx.setFillColor(Ink.white)
            ctx.fillPath()
            ctx.addPath(Shape.grin)
            ctx.setLineWidth(1.15)
            ctx.strokePath()
        case .surprised:
            ctx.addPath(Shape.gasp)
            ctx.setFillColor(Ink.mouth)
            ctx.fillPath()
            ctx.addPath(Shape.gaspTongue)
            ctx.setFillColor(Ink.tongue)
            ctx.fillPath()
            ctx.addPath(Shape.gasp)
            ctx.strokePath()
        case .focused:
            // Tongue out at the corner, concentrating.
            ctx.setFillColor(Ink.tongue)
            ctx.fillEllipse(in: CGRect(x: 1.4, y: 11.2, width: 2.8, height: 2.6))
            ctx.strokeEllipse(in: CGRect(x: 1.4, y: 11.2, width: 2.8, height: 2.6))
            ctx.move(to: CGPoint(x: -4, y: 11.2)); ctx.addLine(to: CGPoint(x: 4, y: 10.8))
            ctx.strokePath()
        case .asleep:
            let r = CGRect(x: -1.6, y: 10.2, width: 3.2, height: 2.8)
            ctx.setFillColor(Ink.mouth)
            ctx.fillEllipse(in: r)
            ctx.strokeEllipse(in: r)
        case .dizzy:
            ctx.move(to: CGPoint(x: -5, y: 11.6))
            ctx.addQuadCurve(to: CGPoint(x: -1.7, y: 11.4), control: CGPoint(x: -3.3, y: 9.6))
            ctx.addQuadCurve(to: CGPoint(x: 1.7, y: 11.4), control: CGPoint(x: 0, y: 13.2))
            ctx.addQuadCurve(to: CGPoint(x: 5, y: 11.4), control: CGPoint(x: 3.3, y: 9.6))
            ctx.strokePath()
        case .neutral:
            // A lopsided smirk, already halfway to the grin.
            ctx.move(to: CGPoint(x: -4, y: 10.8))
            ctx.addQuadCurve(to: CGPoint(x: 4.4, y: 10), control: CGPoint(x: 0.4, y: 13.6))
            ctx.strokePath()
        }
    }

    // MARK: Hat

    private static let hatHop: CGFloat = 1.8

    /// Moves to where the hat sits: it hops when he's startled, slips when he's dizzy, and
    /// tips forward over his eyes as he nods off.
    private static func inHatSpace(_ ctx: CGContext, _ pose: Pose, turn: CGFloat, _ draw: () -> Void) {
        let d = pose.drowse
        var drop = -1 + d * 14
        var tilt = d * 0.1
        switch pose.expression {
        case .surprised: drop -= hatHop
        case .dizzy: tilt += 0.17 + pose.earR * 0.35
        default: break
        }
        ctx.saveGState()
        ctx.translateBy(x: turn * 0.4, y: drop)
        ctx.rotate(by: tilt)
        draw()
        ctx.restoreGState()
    }

    /// The crown leans toward us as the hat tips, so it looks shorter.
    private static func inCrownSpace(_ ctx: CGContext, _ pose: Pose, _ draw: () -> Void) {
        ctx.saveGState()
        ctx.translateBy(x: 0, y: -15)
        ctx.scaleBy(x: 1, y: 1 - pose.drowse * 0.2)
        ctx.translateBy(x: 0, y: 15)
        draw()
        ctx.restoreGState()
    }

    /// Behind everything else, so that it can never cover the pointing hand. The crown hides
    /// its root.
    private static func drawFeather(_ p: Painter, _ pose: Pose) {
        let ctx = p.ctx
        inHatSpace(ctx, pose, turn: pose.turn * 1.25) {
            let root = featherRoot(pose)
            ctx.translateBy(x: root.x, y: root.y)
            // It wilts along the top of the brim as he nods off, clear of the rising Zs, and
            // draws in so that it stops short of his hand.
            ctx.rotate(by: -0.14 - pose.earL * 0.55 - pose.drowse * 0.46)
            let size = 0.92 - pose.drowse * 0.2
            ctx.scaleBy(x: size, y: size)
            p.shape(Shape.feather, Ink.feather)
            if !p.halo {
                ctx.addPath(Shape.featherSpine)
                ctx.setStrokeColor(Ink.featherDark)
                ctx.setLineWidth(1)
                ctx.strokePath()
            }
        }
    }

    /// On the edge of the crown, in hat space.
    private static func featherRoot(_ pose: Pose) -> CGPoint {
        CGPoint(x: -12.5, y: -15 - 9 * (1 - pose.drowse * 0.2))
    }

    private static func drawHat(_ p: Painter, _ pose: Pose, turn: CGFloat) {
        let ctx = p.ctx
        inHatSpace(ctx, pose, turn: turn) {
            inCrownSpace(ctx, pose) { p.shape(Shape.crown, Ink.navyDark) }
            p.shape(Shape.brim, Ink.navy)
            guard !p.halo else { return }
            ctx.addPath(Shape.brimShade)
            ctx.setFillColor(Ink.navyDark)
            ctx.fillPath()
            ctx.addPath(Shape.trim)
            ctx.setStrokeColor(Ink.gold)
            ctx.setLineWidth(1.7)
            ctx.strokePath()
            // The brooch that holds the feather.
            let root = featherRoot(pose)
            ctx.setFillColor(Ink.gold)
            ctx.setStrokeColor(Ink.line)
            ctx.setLineWidth(0.8)
            let brooch = CGRect(x: root.x - 2, y: root.y - 2, width: 4, height: 4)
            ctx.fillEllipse(in: brooch)
            ctx.strokeEllipse(in: brooch)
        }
    }

    // MARK: Parrot

    private static func drawParrot(_ p: Painter, _ pose: Pose) {
        let ctx = p.ctx
        let up = raised(pose)

        // Rides the shoulder; when the spyglass comes up, it hops to the hat to make room.
        let shoulder = CGPoint(x: 12.6, y: 3.5)
        let perch = headPoint(16.5 + pose.turn * 0.5, -20.5, pose)
        var feet = mix(shoulder, perch, up)
        feet.y -= sin(up * .pi) * 7

        let awake = 1 - pose.drowse
        var flap: CGFloat = abs(pose.armSwing) * 0.8
        var crest: CGFloat = 0
        var squawk = false
        var eye = ParrotEye.open
        switch pose.expression {
        case .happy, .excited:
            flap = min(max(1 + (pose.tailAngle + 0.75) * 3, 0.2), 2)
            squawk = true
        case .surprised:
            flap = max(flap, 1.3)
            crest = 0.5
            squawk = true
            eye = .wide
        case .dizzy:
            eye = .crossed
        case .asleep:
            eye = .shut
        default:
            break
        }

        ctx.saveGState()
        ctx.translateBy(x: feet.x, y: feet.y)
        // Lean is in screen space and this is in mirrored body space, so it has to follow the
        // facing for the parrot to trail out behind rather than swing into his face.
        let sign: CGFloat = pose.facing < 0 ? -1 : 1
        ctx.rotate(by: mix(0.22, 0.06, up) - pose.lean * 0.6 * sign)

        p.shape(Shape.parrotTail, Ink.scarletDark)
        if !p.halo, up < 0.5 {
            ctx.addPath(Shape.parrotClaws)
            ctx.setStrokeColor(Ink.line)
            ctx.setLineWidth(1.2)
            ctx.strokePath()
        }
        p.shape(Shape.parrotBody, Ink.scarlet)

        // Head: flicks outward on earR, and tucks down into the wing as it nods off. By then
        // the crest has gone and only the tip of the beak still shows.
        let tucked = smooth((pose.drowse - 0.6) / 0.4)
        let headTurn = -min(pose.earR, 0.25) * 0.8 * awake + pose.drowse * 0.7 + tucked * 0.5
        ctx.saveGState()
        ctx.translateBy(x: mix(1.4, -1.8, pose.drowse), y: mix(-8.4, -5.1, pose.drowse))
        ctx.rotate(by: headTurn)
        if tucked < 1 {
            ctx.saveGState()
            ctx.translateBy(x: -0.8, y: -7)
            ctx.rotate(by: -crest - pose.drowse * 0.9)
            ctx.scaleBy(x: 1 - tucked, y: 1 - tucked)
            ctx.translateBy(x: 0.8, y: 7)
            p.shape(Shape.parrotCrest, Ink.scarlet, line: 1)
            ctx.restoreGState()
            ctx.saveGState()
            ctx.translateBy(x: 4, y: -2.6)
            if squawk { ctx.rotate(by: 0.55) }
            ctx.scaleBy(x: 1 - tucked, y: 1 - tucked)
            ctx.translateBy(x: -4, y: 2.6)
            p.shape(Shape.beakLower, Ink.beak, line: 1)
            ctx.restoreGState()
        }
        ctx.saveGState()
        ctx.translateBy(x: 4, y: -4.5)
        ctx.scaleBy(x: 1 - tucked * 0.4, y: 1 - tucked * 0.4)
        ctx.translateBy(x: -4, y: 4.5)
        p.shape(Shape.beakUpper, Ink.beak, line: 1)
        ctx.restoreGState()
        p.shape(Shape.parrotHead, Ink.scarlet)
        if !p.halo {
            if eye != .shut {
                ctx.addPath(Shape.parrotCheek)
                ctx.setFillColor(Ink.cream)
                ctx.fillPath()
            }
            drawParrotEye(ctx, eye, headTurn: headTurn)
        }
        ctx.restoreGState()

        // Wing: the blue with the yellow patch at its shoulder. Flaps out to the front.
        ctx.saveGState()
        ctx.translateBy(x: -1.2, y: mix(-7.6, -8.4, pose.drowse))
        ctx.rotate(by: -flap)
        p.shape(Shape.wing, Ink.wing)
        if !p.halo {
            ctx.addPath(Shape.wingTip)
            ctx.setStrokeColor(Ink.wingDark)
            ctx.setLineWidth(0.9)
            ctx.strokePath()
            ctx.addPath(Shape.wingPatch)
            ctx.setFillColor(Ink.patch)
            ctx.fillPath()
        }
        ctx.restoreGState()

        ctx.restoreGState()
    }

    private enum ParrotEye { case open, wide, shut, crossed }

    private static func drawParrotEye(_ ctx: CGContext, _ eye: ParrotEye, headTurn: CGFloat) {
        let c = CGPoint(x: 2, y: -4.1)
        switch eye {
        case .open:
            ctx.setFillColor(Ink.line)
            ctx.fillEllipse(in: CGRect(x: c.x - 1.2, y: c.y - 1.3, width: 2.4, height: 2.6))
            ctx.setFillColor(Ink.white)
            ctx.fillEllipse(in: CGRect(x: c.x - 0.8, y: c.y - 1, width: 0.9, height: 0.9))
        case .wide:
            ctx.setStrokeColor(Ink.line)
            ctx.setLineWidth(0.8)
            ctx.strokeEllipse(in: CGRect(x: c.x - 1.8, y: c.y - 1.8, width: 3.6, height: 3.6))
            ctx.setFillColor(Ink.line)
            ctx.fillEllipse(in: CGRect(x: c.x - 0.6, y: c.y - 0.6, width: 1.2, height: 1.2))
        case .shut:
            // Stays level however far the head has turned, or it stops reading as an eye.
            ctx.saveGState()
            ctx.translateBy(x: c.x, y: c.y)
            ctx.rotate(by: -headTurn)
            Kit.arc(ctx, CGPoint(x: -2, y: -0.2), CGPoint(x: 0, y: 1.8), CGPoint(x: 2, y: -0.2), width: 1.2)
            ctx.restoreGState()
        case .crossed:
            ctx.setStrokeColor(Ink.line)
            ctx.setLineWidth(0.9)
            ctx.move(to: CGPoint(x: c.x - 1.2, y: c.y - 1.2)); ctx.addLine(to: CGPoint(x: c.x + 1.2, y: c.y + 1.2))
            ctx.move(to: CGPoint(x: c.x + 1.2, y: c.y - 1.2)); ctx.addLine(to: CGPoint(x: c.x - 1.2, y: c.y + 1.2))
            ctx.strokePath()
        }
    }

    // MARK: Coins

    private static func drawCoins(_ ctx: CGContext, _ pose: Pose) {
        for s in pose.sparkles where s.alpha > 0.01 {
            // They stay solid gold and shrink away at the end, rather than fading to a brown smear.
            let size = s.size * min(s.alpha * 3, 1)
            let spin = cos(s.rot)
            let rx = max(abs(spin), 0.3) * size
            let face = CGRect(x: s.pos.x - rx, y: s.pos.y - size, width: rx * 2, height: size * 2)
            ctx.setFillColor(spin >= 0 ? Ink.gold : Ink.goldDark)
            ctx.setStrokeColor(Ink.line)
            ctx.setLineWidth(0.6 + 0.3 * abs(spin))
            ctx.fillEllipse(in: face)
            ctx.strokeEllipse(in: face)
            if abs(spin) > 0.35 {
                // The rim.
                ctx.setStrokeColor(spin >= 0 ? Ink.goldDark : Ink.gold)
                ctx.setLineWidth(0.7)
                ctx.strokeEllipse(in: face.insetBy(dx: rx * 0.42, dy: size * 0.42))
            }
        }
    }
}
