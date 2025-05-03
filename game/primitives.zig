const std = @import("std");

pub const Point = struct {
    x: f32,
    y: f32,

    pub fn init(x: f32, y: f32) Point {
        return .{ .x = x, .y = y };
    }

    // pub fn toVec2(self: Point) Vec2 {
    //     return Vec2{ self.x, self.y };
    // }
};

pub const Line = struct {
    start: Point,
    end: Point,

    pub fn init(start: Point, end: Point) Point {
        return .{ .start = start, .end = end };
    }
};

pub const Rectangle = struct {
    origin: Point,
    width: f32,
    height: f32,
};

pub const Circle = struct {
    origin: Point,
    radius: f32,
};

pub const Ellipse = struct {
    origin: Point,
    semiMinor: f32,
    semiMajor: f32,
};

pub const Color = struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32,

    pub fn init(r: f32, g: f32, b: f32, a: f32) Color {
        return .{ .r = r, .g = g, .b = b, .a = a };
    }

    pub fn initFromInt(r: u8, g: u8, b: u8, a: u8) Color {
        return .{
            .r = @as(f32, @floatFromInt(r)) / 255.0,
            .g = @as(f32, @floatFromInt(g)) / 255.0,
            .b = @as(f32, @floatFromInt(b)) / 255.0,
            .a = @as(f32, @floatFromInt(a)) / 255.0,
        };
    }
};
