const rend = @import("types.zig").rend;

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
