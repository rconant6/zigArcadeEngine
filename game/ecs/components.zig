const rend = @import("types.zig").rend;

pub const TransformComp = struct {
    // TODO: turn this into a V2
    // and add rot and scale later once it is running
    x: f32,
    y: f32,
};

const Color = rend.Color;
const ShapeType = rend.ShapeType;

pub const ShapeData = union(ShapeType) {
    Circle: rend.Circle,
    Ellipse: rend.Ellipse,
    Line: rend.Line,
    Rectangle: rend.Rectangle,
    Triangle: rend.Triangle,
    Polygon: rend.Polygon,
};

pub const RenderComp = struct {
    shapeType: ShapeType,
    shapeData: ShapeData,
    fillColor: ?Color,
    outlineColor: ?Color,
    visible: bool,
};
