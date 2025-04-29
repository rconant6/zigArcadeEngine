const std = @import("std");

const FrameBuffer = @import("frameBuffer.zig").FrameBuffer;

const prm = @import("primitives.zig");
const Point = prm.Point;
const Line = prm.Line;
const Rectangle = prm.Rectangle;
const Circle = prm.Circle;
const Ellipse = prm.Ellipse;

pub const Renderer = struct {
    frameBuffer: FrameBuffer,
    width: i32,
    height: i32,
    allocator: *std.mem.Allocator,
    clearColor: Color,

    pub fn init(allocator: *std.mem.Allocator, width: i32, height: i32) Renderer {
        const frameBuffer = FrameBuffer.init(allocator, width, height) catch {
            unreachable;
        };
        return Renderer{
            .frameBuffer = frameBuffer,
            .width = width,
            .height = height,
            .allocator = allocator,
            .clearColor = Color.init(1, 0, 1, 1),
        };
    }
    pub fn deinit(self: *Renderer) void {
        self.frameBuffer.deinit();
    }

    pub fn beginFrame(self: *Renderer) void {
        self.frameBuffer.clear(self.clearColor);
    }

    pub fn endFrame(self: *Renderer) void {
        self.frameBuffer.swapBuffers();
    }

    pub fn clear(self: *Renderer) void {
        self.frameBuffer.clear(self.clearColor);
    }

    // MARK: Drawing
    pub fn draw(self: *Renderer) void { // probably called when we do batching
        _ = self;
    }

    pub fn drawPoint(self: *Renderer, point: Point, color: Color) void {
        const screenPos = self.gameToScreenCoords(point.x, point.y);

        if (screenPos.x < 0 or screenPos.x >= self.width or
            screenPos.y < 0 or screenPos.y >= self.height)
            return;

        self.frameBuffer.setPixel(screenPos.x, screenPos.y, color);
    }

    fn getOctant(dx: i32, dy: i32) Octant {
        const absdx = @abs(dx);
        const absdy = @abs(dy);

        // Special cases
        if (dx == 0) return .Vertical;
        if (dy == 0) return .Horizontal;
        if (absdx == absdy) return .Diagonal;

        // Non-specific cases
        const octantCalc: OctantCalc = .{
            .lr = if (dx < 0) true else false,
            .ud = if (dy < 0) true else false,
            .steep = if (absdy > absdx) true else false,
        };
        const octantInt: u8 = @bitCast(octantCalc);
        return @enumFromInt(octantInt);
    }

    fn drawHorizontalLine(self: *Renderer, data: BresenData, color: Color) void {
        var x = data.x;
        const y = data.y;
        const endx = data.endx;
        const step = data.stepx;

        while (x != endx + step) {
            self.frameBuffer.setPixel(x, y, color);
            x += step;
        }
    }

    fn drawVerticalLine(self: *Renderer, data: BresenData, color: Color) void {
        const x = data.x;
        var y = data.y;
        const endy = data.endy;
        const step = data.stepy;

        while (y != endy + step) {
            self.frameBuffer.setPixel(x, y, color);
            y += step;
        }
    }

    fn drawDiagonalLine(self: *Renderer, data: BresenData, color: Color) void {
        var x = data.x;
        var y = data.y;
        const steps = @abs(data.endx - data.x);

        for (0..steps) |_| {
            self.frameBuffer.setPixel(x, y, color);
            x += data.stepx;
            y += data.stepy;
        }
    }

    fn drawBresenLine(self: *Renderer, data: BresenData, color: Color) void {
        var x = data.x;
        var y = data.y;
        var err = data.err;

        while (x != data.endx) {
            self.frameBuffer.setPixel(x, y, color);
            x += data.stepx;
            err += data.errAdjustment;
            if (err >= 0) {
                y += data.stepy;
                err -= data.errThreshold;
            }
        }
    }

    inline fn getHorizontalBresenData(start: ScreenPoint, end: ScreenPoint) BresenData {
        return .{
            .x = start.x,
            .endx = end.x,
            .y = start.y,
            .endy = start.y, // is this right?
            .stepx = if (end.x > start.x) 1 else -1,
            .stepy = 0,
            .err = 0,
            .errThreshold = 0,
            .errAdjustment = 0,
        };
    }
    inline fn getVerticalBresenData(start: ScreenPoint, end: ScreenPoint) BresenData {
        return .{
            .x = start.x,
            .endx = start.x, // is this right? like above
            .y = start.y,
            .endy = end.y,
            .stepx = 0,
            .stepy = if (end.y > start.y) 1 else -1,
            .err = 0,
            .errThreshold = 0,
            .errAdjustment = 0,
        };
    }
    inline fn getDiagonalBresenData(start: ScreenPoint, end: ScreenPoint) BresenData {
        return .{
            .x = start.x,
            .endx = end.x,
            .y = start.y,
            .endy = end.y,
            .stepx = if (end.x > start.x) 1 else -1,
            .stepy = if (end.y > start.y) 1 else -1,
            .err = 0,
            .errThreshold = 0,
            .errAdjustment = 0,
        };
    }

    inline fn configureFirstQuadrant(start: ScreenPoint, end: ScreenPoint, dx: i32, dy: i32, octant: Octant) BresenData {
        std.debug.assert(octant == .RightSlightUp or octant == .UpSlightRight);
        const absdx: i32 = @intCast(@abs(dx));
        const absdy: i32 = @intCast(@abs(dy));
        return .{
            .x = if (octant == .RightSlightUp) start.x else start.y,
            .endx = if (octant == .RightSlightUp) end.x else end.y,
            .y = if (octant == .RightSlightUp) start.y else start.x,
            .endy = if (octant == .RightSlightUp) end.y else end.x,
            .stepx = 1,
            .stepy = -1,
            .err = -@divFloor(if (octant == .RightSlightUp) dx else dy, 2),
            .errThreshold = if (octant == .RightSlightUp) absdx else absdy,
            .errAdjustment = if (octant == .RightSlightUp) absdy else absdx,
        };
    }
    inline fn configureSecondQuadrant(start: ScreenPoint, end: ScreenPoint, dx: i32, dy: i32, octant: Octant) BresenData {
        std.debug.assert(octant == .RightSlightDown or octant == .DownSlightRight);
        const absdx: i32 = @intCast(@abs(dx));
        const absdy: i32 = @intCast(@abs(dy));
        return .{
            .x = if (octant == .RightSlightDown) start.x else start.y,
            .endx = if (octant == .RightSlightDown) end.x else end.y,
            .y = if (octant == .RightSlightDown) start.y else start.x,
            .endy = if (octant == .RightSlightDown) end.y else end.x,
            .stepx = 1,
            .stepy = 1,
            .err = -@divFloor(if (octant == .RightSlightDown) absdx else absdy, 2),
            .errThreshold = if (octant == .RightSlightDown) absdx else absdy,
            .errAdjustment = if (octant == .RightSlightDown) absdy else absdx,
        };
    }
    inline fn configureThirdQuadrant(start: ScreenPoint, end: ScreenPoint, dx: i32, dy: i32, octant: Octant) BresenData {
        std.debug.assert(octant == .LeftSlightDown or octant == .DownSlightLeft);
        const absdx: i32 = @intCast(@abs(dx));
        const absdy: i32 = @intCast(@abs(dy));
        return .{
            .x = if (octant == .LeftSlightDown) end.x else end.y,
            .endx = if (octant == .LeftSlightDown) start.x else start.y,
            .y = if (octant == .LeftSlightDown) end.y else end.x,
            .endy = if (octant == .LeftSlightDown) start.y else start.x,
            .stepx = 1,
            .stepy = -1,
            .err = -@divFloor(if (octant == .LeftSlightDown) absdx else absdy, 2),
            .errThreshold = if (octant == .LeftSlightDown) absdx else absdy,
            .errAdjustment = if (octant == .LeftSlightDown) absdy else absdx,
        };
    }
    inline fn configureFourthQuadrant(start: ScreenPoint, end: ScreenPoint, dx: i32, dy: i32, octant: Octant) BresenData {
        std.debug.assert(octant == .LeftSlightUp or octant == .UpSlightLeft);
        const absdx: i32 = @intCast(@abs(dx));
        const absdy: i32 = @intCast(@abs(dy));
        return .{
            .x = if (octant == .LeftSlightUp) end.x else end.y,
            .endx = if (octant == .LeftSlightUp) start.x else start.y,
            .y = if (octant == .LeftSlightUp) end.y else end.x,
            .endy = if (octant == .LeftSlightUp) start.y else start.x,
            .stepx = 1,
            .stepy = 1,
            .err = -@divFloor(if (octant == .LeftSlightUp) absdx else absdy, 2),
            .errThreshold = if (octant == .LeftSlightUp) absdx else absdy,
            .errAdjustment = if (octant == .LeftSlightUp) absdy else absdx,
        };
    }

    fn getBresenData(octant: Octant, start: ScreenPoint, end: ScreenPoint, dx: i32, dy: i32) BresenData {
        return switch (octant) {
            .Horizontal => getHorizontalBresenData(start, end),
            .Vertical => getVerticalBresenData(start, end),
            .Diagonal => getDiagonalBresenData(start, end),
            .RightSlightUp, .UpSlightRight => |o| configureFirstQuadrant(start, end, dx, dy, o),
            .RightSlightDown, .DownSlightRight => |o| configureSecondQuadrant(start, end, dx, dy, o),
            .LeftSlightDown, .DownSlightLeft => |o| configureThirdQuadrant(start, end, dx, dy, o),
            .LeftSlightUp, .UpSlightLeft => |o| configureFourthQuadrant(start, end, dx, dy, o),
        };
    }

    pub fn drawLinePts(self: *Renderer, start: Point, end: Point, color: Color) void {
        const screenStart = self.gameToScreenCoords(start.x, start.y);
        const screenEnd = self.gameToScreenCoords(end.x, end.y);

        if (screenStart.isSamePoint(screenEnd)) return self.drawPoint(start, color);

        const dx: i32 = screenEnd.x - screenStart.x;
        const dy: i32 = screenEnd.y - screenStart.y;

        const octant = getOctant(dx, dy);
        const data = getBresenData(octant, screenStart, screenEnd, dx, dy);

        return switch (octant) {
            .Horizontal => drawHorizontalLine(self, data, color),
            .Vertical => drawVerticalLine(self, data, color),
            .Diagonal => drawDiagonalLine(self, data, color),
            else => drawBresenLine(self, data, color),
        };
    }

    pub fn drawLine(self: *Renderer, line: Line, color: Color) void {
        self.drawLinePts(line.start, line.end, color);
    }

    pub fn getRawFrameBuffer(self: *const Renderer) []const Color {
        return self.frameBuffer.frontBuffer;
    }

    fn gameToScreenCoords(self: *const Renderer, x: f32, y: f32) ScreenPoint {
        const fw: f32 = @floatFromInt(self.width);
        const fh: f32 = @floatFromInt(self.height);
        const screenX: i32 = @intFromFloat((x + 1.0) * 0.5 * fw);
        const screenY: i32 = @intFromFloat((1.0 - y) * 0.5 * fh);

        return .{ .x = screenX, .y = screenY };
    }
};

// MARK: Types
const BresenData = struct {
    x: i32 = 0,
    y: i32 = 0,
    endx: i32 = 0,
    endy: i32 = 0,
    stepx: i32 = 0,
    stepy: i32 = 0,
    err: i32 = 0,
    errThreshold: i32 = 0,
    errAdjustment: i32 = 0,
};

const OctantCalc = packed struct {
    lr: bool,
    ud: bool,
    steep: bool,
    zeros: u5 = 0,
};

const Octant = enum {
    RightSlightUp, // 000: dx>0, dy>0, |dx|>|dy|
    LeftSlightDown, // 001: dx<0, dy>0, |dx|>|dy|
    RightSlightDown, // 010: dx>0, dy<0, |dx|>|dy|
    LeftSlightUp, // 011: dx<0, dy<0, |dx|>|dy|
    UpSlightRight, // 100: dx>0, dy>0, |dx|<|dy|
    UpSlightLeft, // 101: dx<0, dy>0, |dx|<|dy|
    DownSlightRight, // 110: dx>0, dy<0, |dx|<|dy|
    DownSlightLeft, // 111: dx<0, dy<0, |dx|<|dy|

    // Special cases remain the same
    Horizontal, // dx ≠ 0, dy = 0
    Vertical, // dx = 0, dy ≠ 0
    Diagonal, // |dx| = |dy|
};
const ScreenPoint = struct {
    x: i32,
    y: i32,

    fn isSamePoint(self: *const ScreenPoint, otherPoint: ScreenPoint) bool {
        return self.x == otherPoint.x and self.y == otherPoint.y;
    }
};

pub const Color = struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32,

    pub fn init(r: f32, g: f32, b: f32, a: f32) Color {
        return .{ .r = r, .g = g, .b = b, .a = a };
    }

    // pub fn toVec4(self: Color) @Vector(4, f32) {
    //     return .{ self.r, self.g, self.b, self.a };
    // }
};

pub const Transform = struct {
    position: Point,
    rotation: f32,
    scale: f32,
};
