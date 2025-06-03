const std = @import("std");
const rend = @import("types.zig").rend;

pub const LineConfig = struct {
    pos: ?rend.Point = rend.Point{ .x = 0, .y = 0 }, // Translation away from the origin
    rot: ?f32 = null,
    scale: ?f32 = null,

    start: rend.Point = rend.Point{ .x = -0.1, .y = 0 },
    end: rend.Point = rend.Point{ .x = 0.1, .y = 0 },
    color: rend.Color,
};

pub const CircleConfig = struct {
    pos: ?rend.Point = rend.Point{ .x = 0, .y = 0 }, // Translation away from the origin
    rot: ?f32 = null,
    scale: ?f32 = null,

    origin: rend.Point = rend.Point{ .x = 0, .y = 0 }, // Where in screenspace you want this to spawn/originate from
    radius: f32 = 0.1,
    outlineColor: ?rend.Color = null,
    fillColor: ?rend.Color = null,
};

pub const ShapeConfigs = union(enum) {
    Circle: CircleConfig,
    // Ellipse,
    Line: LineConfig,
    // Rectangle,
    // Triangle,
    // Polygon,
};
