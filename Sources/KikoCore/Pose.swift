import CoreGraphics

/// What the system wants the pointer to look like right now.
public enum CursorKind: Equatable {
    /// Plain arrow: Kiko's finger is the pointer.
    case arrow
    /// Pointing hand over a link or button: finger is the pointer, Kiko perks up.
    case link
    /// Anything else (I-beam, resize, crosshair, custom): the real cursor image is
    /// drawn at the hotspot so precision work stays readable, and Kiko stands aside.
    case other
}

public enum Expression: Equatable {
    case neutral, happy, surprised, asleep, dizzy, focused, excited
}

public struct Sparkle {
    public var pos: CGPoint
    public var size: CGFloat
    public var rot: CGFloat
    public var alpha: CGFloat
}

public struct Zee {
    public var pos: CGPoint
    public var size: CGFloat
    public var alpha: CGFloat
}

/// One round cloud of smoke.
public struct Puff {
    public var pos: CGPoint
    public var radius: CGFloat
    public var alpha: CGFloat
    public var turn: CGFloat      // settled when it's born, so that it keeps its shape as it drifts

    public init(pos: CGPoint, radius: CGFloat, alpha: CGFloat, turn: CGFloat = 0) {
        self.pos = pos
        self.radius = radius
        self.alpha = alpha
        self.turn = turn
    }
}

/// One frame of the character. All positions are relative to the hotspot (the real
/// mouse position), y pointing down, in unscaled points.
public struct Pose {
    public var avatar = Avatar.kiko
    public var body = CGPoint(x: 36, y: 32)
    public var facing: CGFloat = 1        // +1 faces left, -1 is mirrored
    public var lean: CGFloat = 0          // radians, clockwise positive
    public var squash: CGFloat = 1        // <1 squashed, >1 stretched
    public var bob: CGFloat = 0
    public var headTilt: CGFloat = 0
    public var turn: CGFloat = 0          // -1...1, slides the face sideways for a 3/4 look
    public var look = CGPoint.zero        // -1...1, in the character's own space
    public var blink: CGFloat = 1         // 1 open, 0 shut
    public var expression = Expression.neutral
    public var earL: CGFloat = 0
    public var earR: CGFloat = 0
    public var tailAngle: CGFloat = -0.75
    public var legSwing: CGFloat = 0
    public var armSwing: CGFloat = 0
    public var fingerTip = CGPoint.zero   // exactly .zero whenever Kiko is the pointer
    public var reach: CGFloat = 1         // 1 pointing at the hotspot, 0 arm relaxed
    public var scarfA: [CGPoint] = []     // the avatar's two chains; see Motion for what each one is
    public var scarfB: [CGPoint] = []
    public var hover: CGFloat = 0         // 0...about 1.1, springs up over a link
    public var drowse: CGFloat = 0        // 0...1, eases up while asleep
    public var vanish: CGFloat = 0        // 0...1, the body is gone in a puff of smoke at 1
    public var sparkles: [Sparkle] = []
    public var puffs: [Puff] = []
    public var zees: [Zee] = []
    public var opacity: CGFloat = 1

    public init() {}
}

/// A system cursor image to draw at the hotspot.
public struct CursorImage {
    public var image: CGImage
    public var size: CGSize
    public var hotSpot: CGPoint

    public init(image: CGImage, size: CGSize, hotSpot: CGPoint) {
        self.image = image
        self.size = size
        self.hotSpot = hotSpot
    }
}
