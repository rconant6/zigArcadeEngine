const std = @import("std");
const rend = @import("types.zig").rend;

// MARK: Transform and Shapes
pub const CircleConfig = struct {
    offset: ?rend.Point = rend.Point{ .x = 0, .y = 0 }, // Translation away from the origin
    rotation: ?f32 = null,
    scale: ?f32 = null,

    origin: rend.Point = rend.Point{ .x = 0, .y = 0 }, // Where in screenspace you want this to spawn/originate from
    radius: f32 = 0.1,
    outlineColor: ?rend.Color = null,
    fillColor: ?rend.Color = null,
};

pub const LineConfig = struct {
    offset: ?rend.Point = rend.Point{ .x = 0, .y = 0 }, // Translation away from the origin
    rotation: ?f32 = null,
    scale: ?f32 = null,

    start: rend.Point = rend.Point{ .x = -0.1, .y = 0 },
    end: rend.Point = rend.Point{ .x = 0.1, .y = 0 },
    color: rend.Color,
};

pub const RectangleConfig = struct {
    offset: ?rend.Point = rend.Point{ .x = 0, .y = 0 }, // Translation away from the origin
    rotation: ?f32 = null,
    scale: ?f32 = null,

    center: rend.Point = rend.Point{ .x = 0, .y = 0 },
    halfWidth: f32 = 0.16,
    halfHeight: f32 = 0.2,
    outlineColor: ?rend.Color,
    fillColor: ?rend.Color,
};

pub const TriangleConfig = struct {
    offset: ?rend.Point = rend.Point{ .x = 0, .y = 0 }, // Translation away from the origin
    rotation: ?f32 = null,
    scale: ?f32 = null,

    vertices: [3]rend.Point = .{
        rend.Point.init(0.15, 0.15),
        rend.Point.init(-0.15, 0.15),
        rend.Point.init(0.0, -0.15),
    },
    outlineColor: ?rend.Color,
    fillColor: ?rend.Color,
};

pub const PolygonConfig = struct {
    offset: ?rend.Point = rend.Point{ .x = 0, .y = 0 }, // Translation away from the origin
    rotation: ?f32 = null,
    scale: ?f32 = null,

    vertices: ?[]rend.Point = null,
    outlineColor: ?rend.Color,
    fillColor: ?rend.Color,
};

pub const EllipseConfig = struct {
    // place holder
};

pub const ShapeConfigs = union(enum) {
    Circle: CircleConfig,
    // Ellipse: EllipseConfig,
    Line: LineConfig,
    Polygon: PolygonConfig,
    Rectangle: RectangleConfig,
    Triangle: TriangleConfig,
};
