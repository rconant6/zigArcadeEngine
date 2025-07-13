const ecs = @import("ecs.zig");
const ShapeData = ecs.ShapeData;
const Transform = ecs.Transform;
const V2 = ecs.V2;

pub const ComponentTag = enum {
    Control,
    Player,
    Render,
    Transform,
    Velocity,
};

pub const ComponentType = union(ComponentTag) {
    Control: ControlComp,
    Player: PlayerComp,
    Render: RenderComp,
    Transform: TransformComp,
    Velocity: VelocityComp,
};

pub const TextComp = struct {
    char: u8 = 0,
};

pub const PlayerComp = struct {
    playerID: u8 = 0,
};

pub const ControlComp = struct {
    rotationRate: ?f32 = null,
    thrustForce: ?f32 = null,
    shotRate: ?f32 = null,
};

pub const TransformComp = struct {
    transform: Transform,
};

pub const RenderComp = struct {
    shapeData: ShapeData,
    visible: bool,
};

pub const VelocityComp = struct {
    velocity: V2 = V2.ZERO,
};
