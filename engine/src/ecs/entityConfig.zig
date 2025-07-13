const std = @import("std");

const ecs = @import("ecs.zig");
const Color = ecs.Color;
const Point = ecs.V2;

// MARK: Controls / Player configs
pub const ControllableConfig = struct {
    playerID: ?u8 = null,
    rotationRate: ?f32 = null,
    thrustForce: ?f32 = null,
    shotRate: ?f32 = null,
};

// MARK: Transform and Shapes
pub const CircleConfig = struct {
    offset: ?Point = Point{ .x = 0, .y = 0 }, // Translation away from the origin
    rotation: ?f32 = null,
    scale: ?f32 = null,

    origin: Point = Point{ .x = 0, .y = 0 }, // Where in screenspace you want this to spawn/originate from
    radius: f32 = 0.1,
    outlineColor: ?Color = null,
    fillColor: ?Color = null,
};

pub const LineConfig = struct {
    offset: ?Point = Point{ .x = 0, .y = 0 }, // Translation away from the origin
    rotation: ?f32 = null,
    scale: ?f32 = null,

    start: Point = Point{ .x = -0.1, .y = 0 },
    end: Point = Point{ .x = 0.1, .y = 0 },
    color: Color,
};

pub const RectangleConfig = struct {
    offset: ?Point = Point{ .x = 0, .y = 0 }, // Translation away from the origin
    rotation: ?f32 = null,
    scale: ?f32 = null,

    center: Point = Point{ .x = 0, .y = 0 },
    halfWidth: f32 = 0.16,
    halfHeight: f32 = 0.2,
    outlineColor: ?Color,
    fillColor: ?Color,
};

pub const TriangleConfig = struct {
    offset: ?Point = Point{ .x = 0, .y = 0 }, // Translation away from the origin
    rotation: ?f32 = null,
    scale: ?f32 = null,

    vertices: [3]Point = .{
        .{ .x = 0.15, .y = 0.15 },
        .{ .x = -0.15, .y = 0.15 },
        .{ .x = 0.0, .y = -0.15 },
    },
    outlineColor: ?Color,
    fillColor: ?Color,
};

pub const PolygonConfig = struct {
    offset: ?Point = Point{ .x = 0, .y = 0 }, // Translation away from the origin
    rotation: ?f32 = null,
    scale: ?f32 = null,

    vertices: ?[]const Point = null,
    outlineColor: ?Color,
    fillColor: ?Color,
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
