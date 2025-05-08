// Purely a bridge file shared in the renderer system
const std = @import("std");

pub const Renderer = @import("core.zig").Renderer;

pub const col = @import("color.zig");
pub const Color = col.Color;

pub const fb = @import("frameBuffer.zig");
pub const FrameBuffer = fb.FrameBuffer;

pub const prim = @import("primitives.zig");
pub const Circle = prim.Circle;
pub const Ellipse = prim.Ellipse;
pub const Line = prim.Line;
pub const Rectangle = prim.Rectangle;
pub const Triangle = prim.Triangle;
pub const Polygon = prim.Polygon;

/// Represents a 2D point in game space with x and y coordinates.
///
/// Points use floating-point coordinates in the range of -1.0 to 1.0 for both axes,
/// where (0,0) is the center of the screen. The top-right corner is at (1,1) and
/// the bottom-left corner is at (-1,-1).
///
/// Example:
///     const centerPoint = Point{ .x = 0, .y = 0 };     // Center of screen
///     const topRight = Point{ .x = 1, .y = 1 };        // Top-right corner
///     const customPoint = Point.init(0.5, -0.3);       // Using the init helper
pub const GamePoint = struct {
    x: f32,
    y: f32,

    pub fn init(x: f32, y: f32) GamePoint {
        return .{ .x = x, .y = y };
    }
};

/// Represents a 2D point in screen space with x and y coordinates.
///
/// Points use i32 coordinates in the range of 0 to width and 0 to hieght for both axes,
/// where (0,0) is the top-left of the screen. The bottom-right corner is at (width, height) and
///
/// Example:
///     const centerPoint = Point{ .x = width / 2, .y = height / 2 };     // Center of screen
///     const topLeft = Point{ .x = 0, .y = 0 };                          // Top-left corner
///     const bottomRight = Point.init(width, height);                    // Using the init helper
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
