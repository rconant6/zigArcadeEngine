const rend = @import("types.zig").rend;

pub const TransformComp = struct {
    transform: rend.Transform,
};

pub const RenderComp = struct {
    shapeData: rend.ShapeData,
    visible: bool,
};
