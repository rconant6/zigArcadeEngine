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
    center: Point,
    halfWidth: f32,
    halfHeight: f32,

    pub fn initSquare(center: Point, size: f32) Rectangle {
        return .{
            .center = center,
            .halfWidth = size * 0.5,
            .halfHeight = size * 0.5,
        };
    }

    pub fn initFromCenter(center: Point, width: f32, height: f32) Rectangle {
        return .{
            .center = center,
            .halfWidth = width * 0.5,
            .halfHeight = height * 0.5,
        };
    }

    pub fn initFromTopLeft(topLeft: Point, width: f32, height: f32) Rectangle {
        return .{
            .center = .{
                .x = topLeft.x + width * 0.5,
                .y = topLeft.y + height * 0.5,
            },
            .halfWidth = width,
            .halfHeight = height,
        };
    }

    pub fn getWidth(self: Rectangle) f32 {
        return self.halfWidth * 2;
    }

    pub fn getHeight(self: Rectangle) f32 {
        return self.halfHeight * 2;
    }

    /// Returns the points corners of a Rectangle [topLeft, topRight, bottomRight, bottomLeft]
    pub fn getCorners(self: *const Rectangle) [4]Point {
        const topLeft: Point = .{ .x = self.center.x - self.halfWidth, .y = self.center.y + self.halfHeight };
        const topRight: Point = .{ .x = self.center.x + self.halfWidth, .y = self.center.y + self.halfHeight };
        const bottomRight: Point = .{ .x = self.center.x + self.halfWidth, .y = self.center.y - self.halfHeight };
        const bottomLeft: Point = .{ .x = self.center.x - self.halfWidth, .y = self.center.y - self.halfHeight };
        return .{ topLeft, topRight, bottomRight, bottomLeft };
    }
};

pub const Triangle = struct {
    vertices: [3]Point,
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
