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
