const rend = @import("types.zig").rend;
const V2 = @import("../math.zig").V2;

pub const PlayerComp = struct {
    playerID: u8 = 0,
};

pub const ControlComp = struct {
    rotationRate: ?f32 = null,
    thrustForce: ?f32 = null,
    shotRate: ?f32 = null,
};

pub const TransformComp = struct {
    transform: rend.Transform,
};

pub const RenderComp = struct {
    shapeData: rend.ShapeData,
    visible: bool,
};

pub const VelocityComp = struct {
    velocity: V2 = V2.zero(),
};
