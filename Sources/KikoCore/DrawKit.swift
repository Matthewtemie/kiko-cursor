import CoreGraphics

func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha)
}

/// Colours every character shares, so they look like one family.
enum Line {
    static let ink = rgb(0x2A1A3E)
    static let halo = rgb(0xFFFFFF)
    static let white = rgb(0xFFFFFF)
}

extension CGMutablePath {
    func m(_ x: CGFloat, _ y: CGFloat) { move(to: CGPoint(x: x, y: y)) }
    func l(_ x: CGFloat, _ y: CGFloat) { addLine(to: CGPoint(x: x, y: y)) }
    func q(_ cx: CGFloat, _ cy: CGFloat, _ x: CGFloat, _ y: CGFloat) {
        addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: cx, y: cy))
    }
    func c(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat, _ x: CGFloat, _ y: CGFloat) {
        addCurve(to: CGPoint(x: x, y: y), control1: CGPoint(x: x1, y: y1), control2: CGPoint(x: x2, y: y2))
    }
    func z() { closeSubpath() }
}

func path(_ build: (CGMutablePath) -> Void) -> CGPath {
    let p = CGMutablePath()
    build(p)
    return p
}

func mid(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
    CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
}

/// Draws filled, outlined shapes. On the halo pass the same calls lay down a white
/// sticker edge, which is what keeps the characters readable on dark windows.
struct Painter {
    let ctx: CGContext
    let halo: Bool
    private let edge: CGFloat = 2.2

    func shape(_ p: CGPath, _ fill: CGColor, line: CGFloat = 1.15) {
        ctx.addPath(p)
        if halo {
            ctx.setStrokeColor(Line.halo)
            ctx.setLineWidth(line + edge)
            ctx.strokePath()
        } else {
            ctx.setFillColor(fill)
            ctx.setStrokeColor(Line.ink)
            ctx.setLineWidth(line)
            ctx.drawPath(using: .fillStroke)
        }
    }

    func oval(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ fill: CGColor, line: CGFloat = 1.15) {
        shape(CGPath(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2), transform: nil), fill, line: line)
    }

    /// A round-ended tube: dark outline stroke, then the colour on top.
    func limb(_ a: CGPoint, _ ctrl: CGPoint, _ b: CGPoint, width: CGFloat, _ color: CGColor) {
        let p = CGMutablePath()
        p.move(to: a)
        p.addQuadCurve(to: b, control: ctrl)
        ctx.addPath(p)
        if halo {
            ctx.setStrokeColor(Line.halo)
            ctx.setLineWidth(width + 2.3 + edge)
            ctx.strokePath()
        } else {
            ctx.setStrokeColor(Line.ink)
            ctx.setLineWidth(width + 2.3)
            ctx.strokePath()
            ctx.addPath(p)
            ctx.setStrokeColor(color)
            ctx.setLineWidth(width)
            ctx.strokePath()
        }
    }
}

/// The parts every character is built from. Each character's art file draws the rest.
enum Kit {
    /// Moves to the body's centre with its lean, squash and facing applied. A body that has
    /// vanished in smoke shrinks to nothing, but the pointing arm is drawn outside this, so
    /// the fingertip never leaves the pointer.
    static func inBodySpace(_ ctx: CGContext, _ pose: Pose, _ draw: () -> Void) {
        ctx.saveGState()
        ctx.translateBy(x: pose.body.x, y: pose.body.y + pose.bob)
        ctx.rotate(by: pose.lean)
        let sign: CGFloat = pose.facing < 0 ? -1 : 1
        let shrink = 1 - pose.vanish * 0.96
        ctx.scaleBy(x: sign * max(abs(pose.facing), 0.14) * (2 - pose.squash) * shrink, y: pose.squash * shrink)
        draw()
        ctx.restoreGState()
    }

    /// Moves from body space to the centre of the head, tilted.
    static func inHeadSpace(_ ctx: CGContext, _ pose: Pose, _ draw: () -> Void) {
        ctx.saveGState()
        ctx.translateBy(x: 0, y: -1)
        ctx.rotate(by: pose.headTilt)
        ctx.translateBy(x: 0, y: -14.5)
        draw()
        ctx.restoreGState()
    }

    /// A ribbon along a chain, from `rootWidth` half-width to `tipWidth`, ending in a
    /// swallowtail notch `notch` deep. A notch of zero gives a plain end.
    static func ribbon(_ pts: [CGPoint], rootWidth: CGFloat, tipWidth: CGFloat, notch: CGFloat) -> CGPath? {
        guard pts.count > 1 else { return nil }
        let path = CGMutablePath()
        var left: [CGPoint] = []
        var right: [CGPoint] = []
        var endDir = CGPoint.zero
        for i in pts.indices {
            let a = pts[max(i - 1, 0)]
            let b = pts[min(i + 1, pts.count - 1)]
            let dx = b.x - a.x, dy = b.y - a.y
            let len = max(hypot(dx, dy), 0.01)
            let t = CGFloat(i) / CGFloat(pts.count - 1)
            let w = rootWidth + (tipWidth - rootWidth) * t
            left.append(CGPoint(x: pts[i].x - dy / len * w, y: pts[i].y + dx / len * w))
            right.append(CGPoint(x: pts[i].x + dy / len * w, y: pts[i].y - dx / len * w))
            endDir = CGPoint(x: dx / len, y: dy / len)
        }
        path.move(to: left[0])
        for i in 1..<left.count {
            path.addQuadCurve(to: mid(left[i - 1], left[i]), control: left[i - 1])
        }
        path.addLine(to: left[left.count - 1])
        let end = pts[pts.count - 1]
        path.addLine(to: CGPoint(x: end.x - endDir.x * notch, y: end.y - endDir.y * notch))
        path.addLine(to: right[right.count - 1])
        for i in stride(from: right.count - 1, to: 0, by: -1) {
            path.addQuadCurve(to: mid(right[i], right[i - 1]), control: right[i])
        }
        path.addLine(to: right[0])
        path.closeSubpath()
        return path
    }

    /// As a character turns round its body narrows, but the chains aren't drawn in body space, so
    /// their roots would be left hanging in the air. This moves a root by as much as the place it's
    /// tied to has moved, fading out along the chain so that the free end stays where it is.
    static func tucked(_ pts: [CGPoint], _ pose: Pose) -> [CGPoint] {
        guard let root = pts.first, pts.count > 1 else { return pts }
        let c = cos(pose.lean), s = sin(pose.lean)
        let ox = root.x - pose.body.x, oy = root.y - pose.body.y - pose.bob
        let along = (ox * c + oy * s) * (max(abs(pose.facing), 0.14) * (2 - pose.squash) - 1)
        let across = (oy * c - ox * s) * (pose.squash - 1)
        let dx = along * c - across * s, dy = along * s + across * c
        var out = pts
        for i in pts.indices {
            let left = 1 - CGFloat(i) / CGFloat(pts.count - 1)
            out[i].x += dx * left * left
            out[i].y += dy * left * left
        }
        return out
    }

    /// Where the pointing arm's parts land, worked out from the shoulder and the fingertip.
    private struct ArmLayout {
        let shoulder, wrist, hand, tip: CGPoint
        let ux, uy, sag: CGFloat

        init(_ pose: Pose) {
            let sign: CGFloat = pose.facing < 0 ? -1 : 1
            let lean = pose.lean
            let lx = sign * -7.8, ly: CGFloat = 3.5
            shoulder = CGPoint(x: pose.body.x + lx * cos(lean) - ly * sin(lean),
                               y: pose.body.y + pose.bob + lx * sin(lean) + ly * cos(lean))
            tip = pose.fingerTip

            let dx = tip.x - shoulder.x, dy = tip.y - shoulder.y
            let len = max(hypot(dx, dy), 0.01)
            ux = dx / len
            uy = dy / len

            let fingerReach: CGFloat = 7.6 * max(pose.reach, 0.25)
            hand = CGPoint(x: tip.x - ux * fingerReach, y: tip.y - uy * fingerReach)
            wrist = CGPoint(x: hand.x - ux * 2.6, y: hand.y - uy * 2.6)
            // The sleeve sags more the less it has to stretch.
            sag = max(0, 11 - len * 0.14) * sign
        }
    }

    /// The arm that is the pointer. Every character uses this one, so the click point
    /// can't differ between them: only the colours do.
    static func pointingArm(_ p: Painter, _ pose: Pose, sleeve: CGColor, cuff: CGColor, skin: CGColor) {
        let arm = ArmLayout(pose)
        let ux = arm.ux, uy = arm.uy, wrist = arm.wrist
        let ctrl = CGPoint(x: (arm.shoulder.x + wrist.x) / 2 + uy * arm.sag * -1, y: (arm.shoulder.y + wrist.y) / 2 + ux * arm.sag)
        p.limb(arm.shoulder, ctrl, wrist, width: 4.2, sleeve)

        if !p.halo {
            let band = CGMutablePath()
            band.move(to: CGPoint(x: wrist.x - uy * 2.4, y: wrist.y + ux * 2.4))
            band.addLine(to: CGPoint(x: wrist.x + uy * 2.4, y: wrist.y - ux * 2.4))
            p.ctx.addPath(band)
            p.ctx.setStrokeColor(cuff)
            p.ctx.setLineWidth(1.3)
            p.ctx.strokePath()
        }

        pointingHand(p, arm, skin: skin)
    }

    /// The body can swing across the pointer for a moment, and the fingertip is the pointer, so
    /// the hand always goes on top again. Call this after everything else.
    static func handOnTop(_ ctx: CGContext, _ pose: Pose, skin: CGColor) {
        guard pose.reach > 0.5 else { return }
        pointingHand(Painter(ctx: ctx, halo: false), ArmLayout(pose), skin: skin)
    }

    /// Hand and tapered pointing finger. The outline's outer edge lands exactly on the
    /// tip, so the visible point of the finger is where the click goes.
    private static func pointingHand(_ p: Painter, _ arm: ArmLayout, skin: CGColor) {
        let tip = arm.tip, hand = arm.hand, ux = arm.ux, uy = arm.uy
        let line: CGFloat = 1.05
        let halfWidth: CGFloat = 1.75
        let px = -uy, py = ux
        let fingerEnd = CGPoint(x: tip.x - ux * line / 2, y: tip.y - uy * line / 2)
        let base = CGPoint(x: hand.x + ux * 1.2, y: hand.y + uy * 1.2)
        let waist = mid(base, fingerEnd)
        let finger = CGMutablePath()
        finger.move(to: CGPoint(x: base.x + px * halfWidth, y: base.y + py * halfWidth))
        finger.addQuadCurve(to: fingerEnd, control: CGPoint(x: waist.x + px * halfWidth * 0.95, y: waist.y + py * halfWidth * 0.95))
        finger.addQuadCurve(to: CGPoint(x: base.x - px * halfWidth, y: base.y - py * halfWidth),
                            control: CGPoint(x: waist.x - px * halfWidth * 0.95, y: waist.y - py * halfWidth * 0.95))
        finger.closeSubpath()
        p.shape(finger, skin, line: line)
        p.oval(hand.x, hand.y, 3.3, 3.3, skin, line: line)
        if !p.halo {
            // Hide the seam where the finger meets the palm.
            let seam = CGMutablePath()
            seam.move(to: CGPoint(x: hand.x + ux * 0.6, y: hand.y + uy * 0.6))
            seam.addLine(to: CGPoint(x: base.x + ux * 1.4, y: base.y + uy * 1.4))
            p.ctx.addPath(seam)
            p.ctx.setStrokeColor(skin)
            p.ctx.setLineWidth(halfWidth * 1.75)
            p.ctx.strokePath()
        }
    }

    static func arc(_ ctx: CGContext, _ a: CGPoint, _ c: CGPoint, _ b: CGPoint, width: CGFloat) {
        ctx.move(to: a)
        ctx.addQuadCurve(to: b, control: c)
        ctx.setStrokeColor(Line.ink)
        ctx.setLineWidth(width)
        ctx.strokePath()
    }

    static func spiral(_ ctx: CGContext, flip: CGFloat) {
        let s = CGMutablePath()
        var first = true
        for i in 0...26 {
            let t = CGFloat(i) / 26
            let a = t * .pi * 4.4 * flip
            let r = 0.5 + t * 4.3
            let pt = CGPoint(x: cos(a) * r, y: sin(a) * r + 0.4)
            if first { s.move(to: pt); first = false } else { s.addLine(to: pt) }
        }
        ctx.addPath(s)
        ctx.setStrokeColor(Line.ink)
        ctx.setLineWidth(1.1)
        ctx.strokePath()
    }

    /// A big anime eye, with the expression, blink and gaze all taken from the pose. The
    /// context's origin is the centre of the eye. Pass the character's iris and upper lash.
    static func openEye(_ ctx: CGContext, _ pose: Pose, side: CGFloat, iris: CGGradient, lash: CGPath) {
        let open = max(min(pose.blink, 1), 0)
        if open < 0.2 {
            Kit.arc(ctx, CGPoint(x: -4.6, y: 0.6), CGPoint(x: 0, y: 2.6), CGPoint(x: 4.6, y: 0.6), width: 1.7)
            return
        }

        let surprised = pose.expression == .surprised
        let focused = pose.expression == .focused
        let lookX = pose.look.x * 1.3
        let lookY = pose.look.y * 0.9

        ctx.saveGState()
        ctx.translateBy(x: 0, y: 1.4)
        ctx.scaleBy(x: 1, y: open)
        ctx.translateBy(x: 0, y: -1.4)

        let white = CGRect(x: -4.9, y: -5.9, width: 9.8, height: 12)
        ctx.setFillColor(Line.white)
        ctx.fillEllipse(in: white)

        ctx.saveGState()
        ctx.addEllipse(in: white)
        ctx.clip()

        let rx: CGFloat = surprised ? 2.9 : 4.1
        let ry: CGFloat = surprised ? 3.9 : 5.5
        let irisRect = CGRect(x: lookX - rx, y: 0.4 + lookY - ry, width: rx * 2, height: ry * 2)
        ctx.saveGState()
        ctx.addEllipse(in: irisRect)
        ctx.clip()
        ctx.drawLinearGradient(iris, start: CGPoint(x: 0, y: irisRect.minY), end: CGPoint(x: 0, y: irisRect.maxY), options: [])
        ctx.restoreGState()

        ctx.setStrokeColor(Line.ink)
        ctx.setLineWidth(0.7)
        ctx.strokeEllipse(in: irisRect)

        ctx.setFillColor(Line.ink)
        let prx = rx * 0.5, pry = ry * 0.56
        ctx.fillEllipse(in: CGRect(x: lookX - prx, y: 0.2 + lookY - pry, width: prx * 2, height: pry * 2))

        // Shadow under the upper lid
        ctx.setFillColor(eyeShadow)
        ctx.fill(CGRect(x: -6, y: -6.5, width: 12, height: 3))

        ctx.restoreGState()

        // Highlights stay fixed in the upper left of both eyes, as cel animation does.
        ctx.setFillColor(Line.white)
        if pose.expression == .excited {
            ctx.saveGState()
            ctx.translateBy(x: lookX - 0.8, y: lookY - 0.8)
            ctx.scaleBy(x: 3.4, y: 3.4)
            ctx.addPath(spark)
            ctx.fillPath()
            ctx.restoreGState()
        } else {
            let big: CGFloat = surprised ? 1.1 : 1.75
            ctx.fillEllipse(in: CGRect(x: lookX - 1.9 - big, y: lookY - 2.0 - big, width: big * 2, height: big * 2))
            ctx.setFillColor(rgb(0xFFFFFF, 0.8))
            ctx.fillEllipse(in: CGRect(x: lookX + 1.1, y: lookY + 2.2, width: 1.6, height: 1.6))
        }

        // Upper lash, with a flick at the outer corner.
        ctx.saveGState()
        if side > 0 {
            ctx.scaleBy(x: 1, y: 1)
        } else {
            ctx.scaleBy(x: -1, y: 1)
        }
        if focused { ctx.translateBy(x: 0, y: 1.2) }
        ctx.addPath(lash)
        ctx.setFillColor(Line.ink)
        ctx.fillPath()
        ctx.restoreGState()

        ctx.restoreGState()
    }

    private static let eyeShadow = rgb(0x2A1A3E, 0.18)

    /// A four-pointed sparkle, radius 1.
    static let spark = path {
        $0.m(0, -1); $0.q(0.14, -0.14, 1, 0); $0.q(0.14, 0.14, 0, 1)
        $0.q(-0.14, 0.14, -1, 0); $0.q(-0.14, -0.14, 0, -1); $0.z()
    }

    static func zees(_ ctx: CGContext, _ pose: Pose, color: CGColor) {
        for z in pose.zees where z.alpha > 0.01 {
            ctx.saveGState()
            ctx.setAlpha(z.alpha)
            ctx.translateBy(x: z.pos.x, y: z.pos.y)
            ctx.scaleBy(x: z.size, y: z.size)
            ctx.addPath(zee)
            ctx.setStrokeColor(Line.halo)
            ctx.setLineWidth(3 / z.size)
            ctx.strokePath()
            ctx.addPath(zee)
            ctx.setStrokeColor(color)
            ctx.setLineWidth(1.3 / z.size)
            ctx.strokePath()
            ctx.restoreGState()
        }
    }

    private static let zee = path { $0.m(-1, -1); $0.l(1, -1); $0.l(-1, 1); $0.l(1, 1) }
}
