const std = @import("std");

pub const Renderer = @import("core.zig").Renderer;

pub const col = @import("color.zig");
pub const Color = col.Color;

pub const fb = @import("frameBuffer.zig");
pub const FrameBuffer = fb.FrameBuffer;

pub const Transform = struct {
    pos: ?GamePoint = null,
    rot: ?f32 = null,
    scale: ?f32 = null,
};

pub const ShapeType = enum {
    Circle,
    Ellipse,
    Line,
    Rectangle,
    Triangle,
    Polygon,
};

pub const ShapeData = union(ShapeType) {
    Circle: Circle,
    Ellipse: Ellipse,
    Line: Line,
    Rectangle: Rectangle,
    Triangle: Triangle,
    Polygon: Polygon,
};

pub const prim = @import("primitives.zig");
pub const Circle = prim.Circle;
pub const Ellipse = prim.Ellipse;
pub const Line = prim.Line;
pub const Rectangle = prim.Rectangle;
pub const Triangle = prim.Triangle;
pub const Polygon = prim.Polygon;

pub const GamePoint = struct {
    x: f32,
    y: f32,

    pub fn init(x: f32, y: f32) GamePoint {
        return .{ .x = x, .y = y };
    }
};

pub const ScreenPoint = struct {
    x: i32,
    y: i32,

    pub fn init(x: i32, y: i32) ScreenPoint {
        return .{ .x = x, .y = y };
    }

    pub fn isSamePoint(self: *const ScreenPoint, otherPoint: ScreenPoint) bool {
        return self.x == otherPoint.x and self.y == otherPoint.y;
    }
};
