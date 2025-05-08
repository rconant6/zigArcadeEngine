const std = @import("std");
const draw = @import("drawing.zig");
const rTypes = @import("types.zig");
const transform = @import("transformation.zig");

const Circle = rTypes.Circle;
const Color = rTypes.Color;
const Ellipse = rTypes.Ellipse;
const FrameBuffer = rTypes.FrameBuffer;
const Line = rTypes.Line;
const Point = rTypes.GamePoint;
const Polygon = rTypes.Polygon;
const Rectangle = rTypes.Rectangle;
const ScreenPoint = rTypes.ScreenPoint;
const Triangle = rTypes.Triangle;

pub const Renderer = struct {
    frameBuffer: FrameBuffer,
    width: i32,
    height: i32,
    fw: f32,
    fh: f32,
    allocator: *std.mem.Allocator,
    clearColor: Color,

    pub fn init(allocator: *std.mem.Allocator, width: i32, height: i32) !Renderer {
        const frameBuffer = try FrameBuffer.init(allocator, width, height);

        return Renderer{
            .frameBuffer = frameBuffer,
            .width = width,
            .height = height,
            .fw = @floatFromInt(width),
            .fh = @floatFromInt(height),
            .allocator = allocator,
            .clearColor = Color.init(0, 0, 0, 1),
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

    pub fn setClearColor(self: *Renderer, color: Color) void {
        self.clearColor = color;
    }

    pub fn getRawFrameBuffer(self: *const Renderer) []const Color {
        return self.frameBuffer.frontBuffer;
    }

    pub fn gameToScreen(self: *const Renderer, p: Point) ScreenPoint {
        return transform.gameToScreen(self, p);
    }

    pub fn screenToGame(self: *const Renderer, sp: ScreenPoint) Point {
        return transform.screenToGame(self, sp);
    }

    pub fn drawOutline(self: *Renderer, pts: []const Point, color: Color) void {
        draw.drawOutline(self, pts, color);
    }

    pub fn drawPoint(self: *Renderer, point: Point, color: ?Color) void {
        draw.drawPoint(self, point, color);
    }

    pub fn drawLine(self: *Renderer, start: Point, end: Point, color: ?Color) void {
        draw.drawLine(self, start, end, color);
    }

    pub fn drawCircle(self: *Renderer, circle: Circle, fill: ?Color, outline: ?Color) void {
        draw.drawCircle(self, circle, fill, outline);
    }

    pub fn drawRectangle(self: *Renderer, rect: Rectangle, fill: ?Color, outline: ?Color) void {
        draw.drawRectangle(self, rect, fill, outline);
    }

    pub fn drawTriangle(self: *Renderer, tri: Triangle, fill: ?Color, outline: ?Color) void {
        draw.drawTriangle(self, tri, fill, outline);
    }

    pub fn drawPolygon(self: *Renderer, poly: Polygon, fill: ?Color, outline: ?Color) void {
        draw.drawPolygon(self, poly, fill, outline);
    }
};
