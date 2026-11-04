import CoreGraphics

private enum Ink {
    static let line = Line.ink
    static let halo = Line.halo
    static let skin = rgb(0xFFE6D3)
    static let skinShade = rgb(0xF7C6AE)
    static let hair = rgb(0xF58B3D)
    static let hairDark = rgb(0xD4652A)
    static let hairLight = rgb(0xFFC27A)
    static let cream = rgb(0xFFF3E0)
    static let earInner = rgb(0xFFCDB8)
    static let earTip = rgb(0x5A2E2A)
    static let hoodie = rgb(0x5261C4)
    static let hoodieDark = rgb(0x3D4A9C)
    static let scarf = rgb(0xE8373D)
    static let scarfDark = rgb(0xB4222C)
    static let leg = rgb(0x2F2B55)
    static let shoe = rgb(0xFFFFFF)
    static let blush = rgb(0xFF7E8B, 0.55)
    static let mouth = rgb(0x8E2B3B)
    static let tongue = rgb(0xFF8A94)
    static let spark = rgb(0xFFD84D)
    static let white = Line.white
    static let iris = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                                 colors: [rgb(0x0B4F63), rgb(0x1E9AA6), rgb(0x6DF0D6)] as CFArray,
                                 locations: [0, 0.55, 1])!
}

/// Fixed outlines, built once. Head shapes are centred on the head; everything is in points.
private enum Shape {
    static let face = path {
        $0.m(-16, -3); $0.c(-16, -14, -8, -18, 0, -18); $0.c(8, -18, 16, -14, 16, -3)
        $0.c(16, 5, 8, 12, 0, 14.5); $0.c(-8, 12, -16, 5, -16, -3); $0.z()
    }
    static let hairBack = path {
        $0.m(-19, -6); $0.c(-20, -19, -10, -25, 0, -25); $0.c(10, -25, 20, -19, 19, -6)
        $0.c(20, 2, 21, 9, 18, 15); $0.l(14.5, 10.5); $0.l(11, 15.5); $0.l(7, 10)
        $0.l(-7, 10); $0.l(-11, 15.5); $0.l(-14.5, 10.5); $0.l(-18, 15)
        $0.c(-21, 9, -20, 2, -19, -6); $0.z()
    }
    static let bangs = path {
        $0.m(-17.5, 1); $0.c(-19.5, -12, -11, -22.5, 0, -22.5); $0.c(11, -22.5, 19.5, -12, 17.5, 1)
        $0.q(15.8, -4.5, 13.8, -8.5); $0.q(13, -5, 10.5, -3.2)
        $0.q(9.8, -7, 7.5, -10.5); $0.q(6.5, -6.5, 3.5, -3.8)
        $0.q(2.6, -8, 0.5, -11.5); $0.q(-1, -7, -4.6, -3.8)
        $0.q(-5, -8, -7, -10.5); $0.q(-8, -6.5, -11, -3.2)
        $0.q(-11.6, -5.8, -13.8, -8.5); $0.q(-15.8, -4.5, -17.5, 1); $0.z()
    }
    static let lockL = path {
        $0.m(-17.5, -8); $0.q(-20.8, 5, -16.5, 13.5); $0.q(-14.2, 7, -13.4, -6); $0.z()
    }
    static let lockR = path {
        $0.m(17.5, -8); $0.q(20.8, 5, 16.5, 13.5); $0.q(14.2, 7, 13.4, -6); $0.z()
    }
    static let ear = path {
        $0.m(-6.5, 1.5); $0.q(-7.2, -10, -1.6, -17.5); $0.q(0, -19.2, 1.6, -17.5); $0.q(7.2, -10, 6.5, 1.5); $0.z()
    }
    static let earInner = path {
        $0.m(-3.6, 1); $0.q(-3.9, -7, 0, -12.5); $0.q(3.9, -7, 3.6, 1); $0.z()
    }
    static let torso = path {
        $0.m(-7, -1); $0.c(-10, 4, -10.8, 11, -10.2, 17); $0.q(0, 19.8, 10.2, 17)
        $0.c(10.8, 11, 10, 4, 7, -1); $0.z()
    }
    static let scarfWrap = path {
        $0.m(-9.6, -2.4); $0.q(0, -4.6, 9.6, -2.4); $0.q(11.4, 1, 9.6, 4.2)
        $0.q(0, 6.8, -9.6, 4.2); $0.q(-11.4, 1, -9.6, -2.4); $0.z()
    }
    static let tail = path {
        $0.m(0, -2.5); $0.c(6, -9, 16, -13.5, 24, -8.5); $0.q(30, -4.5, 32, 1)
        $0.q(24, 7.5, 15, 7.5); $0.c(8, 7.5, 3, 5, 0, 2.5); $0.z()
    }
    static let tailTip = path {
        $0.m(21, -14); $0.q(17, -3, 20.5, -1); $0.q(17.5, 2, 19.5, 9); $0.l(36, 9); $0.l(36, -14); $0.z()
    }
    static let lash = path {
        $0.m(-5.3, -2.8); $0.q(-4.8, -6.4, 0, -6.8); $0.q(4.6, -6.6, 5.6, -3.2)
        $0.q(6.8, -2.6, 7.4, -3.8); $0.q(7.2, -1.4, 5.1, -1.8)
        $0.q(4, -5, 0, -5.2); $0.q(-3.8, -5, -5.3, -2.8); $0.z()
    }
}

/// Kiko, the original fox spirit: orange hair and fox ears, a hoodie, a red scarf.
enum KikoArt {
    static func draw(_ pose: Pose, in ctx: CGContext) {
        for halo in [true, false] {
            let p = Painter(ctx: ctx, halo: halo)
            drawScarfTail(p, pose.scarfB)
            drawScarfTail(p, pose.scarfA)
            Kit.inBodySpace(ctx, pose) { drawLowerBody(p, pose) }
            Kit.pointingArm(p, pose, sleeve: Ink.hoodie, cuff: Ink.hoodieDark, skin: Ink.skin)
            Kit.inBodySpace(ctx, pose) { drawHead(p, pose) }
        }
        drawParticles(ctx, pose)
        Kit.handOnTop(ctx, pose, skin: Ink.skin)
    }

    // MARK: Body

    private static func drawScarfTail(_ p: Painter, _ pts: [CGPoint]) {
        // Narrow at the knot, flaring toward the swallowtail end, the classic anime scarf.
        guard let ribbon = Kit.ribbon(pts, rootWidth: 1.9, tipWidth: 3.2, notch: 2.8) else { return }
        p.shape(ribbon, Ink.scarf)
    }

    private static func drawLowerBody(_ p: Painter, _ pose: Pose) {
        let ctx = p.ctx

        // Tail
        ctx.saveGState()
        ctx.translateBy(x: 6, y: 14)
        ctx.rotate(by: pose.tailAngle)
        p.shape(Shape.tail, Ink.hair)
        if !p.halo {
            ctx.saveGState()
            ctx.addPath(Shape.tail)
            ctx.clip()
            ctx.addPath(Shape.tailTip)
            ctx.setFillColor(Ink.cream)
            ctx.fillPath()
            ctx.restoreGState()
            ctx.addPath(Shape.tail)
            ctx.setStrokeColor(Ink.line)
            ctx.setLineWidth(1.15)
            ctx.strokePath()
        }
        ctx.restoreGState()

        // Legs and shoes
        let swing = pose.legSwing
        for (x, s) in [(CGFloat(-4.3), swing), (CGFloat(4.3), -swing)] {
            let foot = CGPoint(x: x + s * 2.6, y: 23.5 - abs(s) * 0.8)
            p.limb(CGPoint(x: x, y: 16.5), CGPoint(x: x, y: 20), foot, width: 3.8, Ink.leg)
            p.oval(foot.x + (x < 0 ? -0.9 : 0.9), foot.y + 1.2, 3.5, 2.4, Ink.shoe)
        }

        // Free arm, behind the torso
        let freeHand = CGPoint(x: 11.5 + pose.armSwing * 2.5, y: 11.5 - abs(pose.armSwing) * 1.2)
        p.limb(CGPoint(x: 7.5, y: 3.5), CGPoint(x: 10.5, y: 6.5), freeHand, width: 4, Ink.hoodie)
        p.oval(freeHand.x + 0.2, freeHand.y + 1, 2.5, 2.5, Ink.skin, line: 1)

        // Torso
        p.shape(Shape.torso, Ink.hoodie)
        if !p.halo {
            // Cel shade down the side away from the viewer's light.
            ctx.saveGState()
            ctx.addPath(Shape.torso)
            ctx.clip()
            ctx.setFillColor(Ink.hoodieDark)
            ctx.fill(CGRect(x: 5.4, y: -2, width: 7, height: 22))
            ctx.restoreGState()
            ctx.addPath(Shape.torso)
            ctx.setStrokeColor(Ink.line)
            ctx.setLineWidth(1.15)
            ctx.strokePath()

            ctx.setStrokeColor(Ink.hoodieDark)
            ctx.setLineWidth(1)
            ctx.move(to: CGPoint(x: 0, y: 5)); ctx.addLine(to: CGPoint(x: 0, y: 11))
            ctx.strokePath()
            ctx.move(to: CGPoint(x: -5.6, y: 13)); ctx.addQuadCurve(to: CGPoint(x: 5.6, y: 13), control: CGPoint(x: 0, y: 10.4))
            ctx.strokePath()
        }

        // Scarf around the neck
        p.shape(Shape.scarfWrap, Ink.scarf)
        if !p.halo {
            ctx.setStrokeColor(Ink.scarfDark)
            ctx.setLineWidth(1)
            ctx.move(to: CGPoint(x: -7.8, y: 1.4)); ctx.addQuadCurve(to: CGPoint(x: 7.8, y: 1.4), control: CGPoint(x: 0, y: 3.2))
            ctx.strokePath()
        }
    }

    // MARK: Head

    private static func drawHead(_ p: Painter, _ pose: Pose) {
        Kit.inHeadSpace(p.ctx, pose) { drawHeadShapes(p, pose) }
    }

    private static func drawHeadShapes(_ p: Painter, _ pose: Pose) {
        let ctx = p.ctx
        let turn = pose.turn * 1.25

        p.shape(Shape.hairBack, Ink.hairDark)

        // Ears sit behind the fringe and slide opposite the face.
        for (x, base, flick) in [(CGFloat(-12), CGFloat(-0.3), -pose.earL), (CGFloat(12), CGFloat(0.3), pose.earR)] {
            ctx.saveGState()
            ctx.translateBy(x: x - turn * 0.5, y: -19.5)
            ctx.rotate(by: base + flick)
            p.shape(Shape.ear, Ink.hair)
            if !p.halo {
                ctx.saveGState()
                ctx.addPath(Shape.ear)
                ctx.clip()
                ctx.setFillColor(Ink.earTip)
                ctx.fill(CGRect(x: -9, y: -21, width: 18, height: 7.2))
                ctx.restoreGState()
                ctx.addPath(Shape.earInner)
                ctx.setFillColor(Ink.earInner)
                ctx.fillPath()
                ctx.addPath(Shape.ear)
                ctx.setStrokeColor(Ink.line)
                ctx.setLineWidth(1.15)
                ctx.strokePath()
            }
            ctx.restoreGState()
        }

        p.shape(Shape.face, Ink.skin)
        if p.halo {
            p.shape(Shape.lockL, Ink.hair)
            p.shape(Shape.lockR, Ink.hair)
            p.shape(Shape.bangs, Ink.hair)
            return
        }

        // Shadow the fringe throws on the forehead.
        ctx.saveGState()
        ctx.addPath(Shape.face)
        ctx.clip()
        ctx.translateBy(x: turn * 0.4, y: 2.1)
        ctx.addPath(Shape.bangs)
        ctx.setFillColor(Ink.skinShade)
        ctx.fillPath()
        ctx.restoreGState()

        // Blush
        for sx in [CGFloat(-1), 1] {
            let rect = CGRect(x: sx * 9.7 + turn - 2.9, y: 8, width: 5.8, height: 2.8)
            ctx.setFillColor(Ink.blush)
            ctx.fillEllipse(in: rect)
        }

        drawEyes(p, pose, turn: turn)
        drawMouth(p, pose, turn: turn)

        // Side locks, then the fringe over their tops and the top of the face.
        p.shape(Shape.lockL, Ink.hair)
        p.shape(Shape.lockR, Ink.hair)
        ctx.saveGState()
        ctx.translateBy(x: turn * 0.4, y: 0)
        p.shape(Shape.bangs, Ink.hair)
        ctx.addPath(hairShine)
        ctx.setStrokeColor(Ink.hairLight)
        ctx.setLineWidth(1.5)
        ctx.strokePath()
        ctx.restoreGState()
    }

    private static let hairShine = path {
        $0.m(-11, -15.5); $0.q(-6, -19.5, -1.5, -19.6)
        $0.m(3.5, -19.4); $0.q(7, -18.8, 9.5, -16.6)
    }

    private static func drawEyes(_ p: Painter, _ pose: Pose, turn: CGFloat) {
        let ctx = p.ctx
        for side in [CGFloat(-1), 1] {
            ctx.saveGState()
            ctx.translateBy(x: side * 6.9 + turn, y: 3.3)

            switch pose.expression {
            case .happy:
                Kit.arc(ctx, CGPoint(x: -4.6, y: 1.4), CGPoint(x: 0, y: -5.2), CGPoint(x: 4.6, y: 1.4), width: 1.9)
            case .asleep:
                Kit.arc(ctx, CGPoint(x: -4.6, y: -0.6), CGPoint(x: 0, y: 3.6), CGPoint(x: 4.6, y: -0.6), width: 1.8)
            case .dizzy:
                Kit.spiral(ctx, flip: side)
            default:
                Kit.openEye(ctx, pose, side: side, iris: Ink.iris, lash: Shape.lash)
            }
            ctx.restoreGState()

            // Brows
            guard pose.expression == .focused || pose.expression == .surprised else { continue }
            let browY: CGFloat = pose.expression == .focused ? -2.6 : -5.4
            let tilt: CGFloat = pose.expression == .focused ? 1.3 : -0.6
            ctx.setStrokeColor(Ink.line)
            ctx.setLineWidth(0.9)
            ctx.move(to: CGPoint(x: side * 10 + turn, y: browY - tilt))
            ctx.addLine(to: CGPoint(x: side * 4.4 + turn, y: browY + tilt))
            ctx.strokePath()
        }
    }

    private static func drawMouth(_ p: Painter, _ pose: Pose, turn: CGFloat) {
        let ctx = p.ctx
        ctx.saveGState()
        ctx.translateBy(x: turn, y: 10.7)
        defer { ctx.restoreGState() }
        ctx.setStrokeColor(Ink.line)
        ctx.setLineWidth(0.95)

        switch pose.expression {
        case .happy, .excited:
            let m = path {
                $0.m(-3.3, -0.9); $0.q(0, -0.1, 3.3, -0.9); $0.q(2.8, 3.5, 0, 3.6); $0.q(-2.8, 3.5, -3.3, -0.9); $0.z()
            }
            ctx.addPath(m)
            ctx.setFillColor(Ink.mouth)
            ctx.fillPath()
            ctx.saveGState()
            ctx.addPath(m)
            ctx.clip()
            ctx.setFillColor(Ink.tongue)
            ctx.fillEllipse(in: CGRect(x: -2.1, y: 1.2, width: 4.2, height: 3.2))
            // A small fang, for the fox.
            let fang = path { $0.m(-2.2, -0.8); $0.l(-0.8, -0.6); $0.l(-1.6, 0.8); $0.z() }
            ctx.addPath(fang)
            ctx.setFillColor(Ink.white)
            ctx.fillPath()
            ctx.restoreGState()
            ctx.addPath(m)
            ctx.strokePath()
        case .surprised:
            let r = CGRect(x: -1.6, y: -1, width: 3.2, height: 3.6)
            ctx.setFillColor(Ink.mouth)
            ctx.fillEllipse(in: r)
            ctx.strokeEllipse(in: r)
        case .focused:
            ctx.move(to: CGPoint(x: -2, y: 0.5)); ctx.addLine(to: CGPoint(x: 2, y: 0.1))
            ctx.strokePath()
        case .asleep:
            ctx.move(to: CGPoint(x: -1.4, y: 0.2))
            ctx.addQuadCurve(to: CGPoint(x: 1.4, y: 0.2), control: CGPoint(x: 0, y: 1.6))
            ctx.strokePath()
        case .dizzy:
            ctx.move(to: CGPoint(x: -3, y: 0.6))
            ctx.addQuadCurve(to: CGPoint(x: -1, y: 0.4), control: CGPoint(x: -2, y: -0.8))
            ctx.addQuadCurve(to: CGPoint(x: 1, y: 0.4), control: CGPoint(x: 0, y: 1.7))
            ctx.addQuadCurve(to: CGPoint(x: 3, y: 0.4), control: CGPoint(x: 2, y: -0.8))
            ctx.strokePath()
        case .neutral:
            // The little cat mouth.
            ctx.move(to: CGPoint(x: -2.7, y: -0.3))
            ctx.addQuadCurve(to: CGPoint(x: 0, y: 0), control: CGPoint(x: -1.4, y: 1.7))
            ctx.addQuadCurve(to: CGPoint(x: 2.7, y: -0.3), control: CGPoint(x: 1.4, y: 1.7))
            ctx.strokePath()
        }
    }

    // MARK: Particles

    private static func drawParticles(_ ctx: CGContext, _ pose: Pose) {
        for s in pose.sparkles where s.alpha > 0.01 {
            ctx.saveGState()
            ctx.setAlpha(s.alpha)
            ctx.translateBy(x: s.pos.x, y: s.pos.y)
            ctx.rotate(by: s.rot)
            ctx.scaleBy(x: s.size, y: s.size)
            ctx.addPath(Kit.spark)
            ctx.setFillColor(Ink.spark)
            ctx.setStrokeColor(Ink.line)
            ctx.setLineWidth(0.9 / s.size)
            ctx.drawPath(using: .fillStroke)
            ctx.restoreGState()
        }
        Kit.zees(ctx, pose, color: Ink.hoodie)
    }
}
