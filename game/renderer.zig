const std = @import("std");

const FrameBuffer = @import("frameBuffer.zig").FrameBuffer;

const prm = @import("primitives.zig");
const Circle = prm.Circle;
const Color = prm.Color;
const Ellipse = prm.Ellipse;
const Line = prm.Line;
const Point = prm.Point;
const Rectangle = prm.Rectangle;

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

    // MARK: Drawing
    fn gameToScreenCoordsFromXY(self: *const Renderer, x: f32, y: f32) ScreenPoint {
        const fw: f32 = @floatFromInt(self.width);
        const fh: f32 = @floatFromInt(self.height);
        const screenX: i32 = @intFromFloat((x + 1.0) * 0.5 * fw);
        const screenY: i32 = @intFromFloat((1.0 - y) * 0.5 * fh);

        return .{ .x = screenX, .y = screenY };
    }

    inline fn gameToScreenCoordsFromPoint(self: *const Renderer, point: Point) ScreenPoint {
        return self.gameToScreenCoordsFromXY(point.x, point.y);
    }

    pub fn getRawFrameBuffer(self: *const Renderer) []const Color {
        return self.frameBuffer.frontBuffer;
    }

    pub fn draw(self: *Renderer) void { // probably called when we do batching
        _ = self;
    }

    pub fn drawPoint(self: *Renderer, point: Point, color: Color) void {
        const screenPos = self.gameToScreenCoordsFromPoint(point);

        if (screenPos.x < 0 or screenPos.x >= self.width or
            screenPos.y < 0 or screenPos.y >= self.height)
            return;

        self.frameBuffer.setPixel(screenPos.x, screenPos.y, color);
    }

    // MARK: Lines
    pub fn drawLinePts(self: *Renderer, start: Point, end: Point, color: Color) void {
        const screenStart = self.gameToScreenCoordsFromPoint(start);
        const screenEnd = self.gameToScreenCoordsFromPoint(end);

        if (screenStart.isSamePoint(screenEnd)) return self.drawPoint(start, color);
        var x = screenStart.x;
        var y = screenStart.y;
        const endX = screenEnd.x;
        const endY = screenEnd.y;

        // Get the differences
        var dx = screenEnd.x - screenStart.x;
        var dy = screenEnd.y - screenStart.y;

        // Determine the sign of the increments
        const stepX: i32 = if (dx < 0) -1 else 1;
        const stepY: i32 = if (dy < 0) -1 else 1;

        // Make dx, dy positive for calculations
        dx = @intCast(@abs(dx));
        dy = @intCast(@abs(dy));

        // Special cases for horizontal, vertical, and diagonal can stay as they are
        if (dx == 0) {
            // Handle vertical case
            while (y != endY) : (y += stepY) {
                self.frameBuffer.setPixel(x, y, color);
            }
        } else if (dy == 0) {
            // Handle horizontal case
            while (x != endX) : (x += stepX) {
                self.frameBuffer.setPixel(x, y, color);
            }
        } else if (dx == dy) {
            // Handle diagonal case
            while (x != endX) {
                self.frameBuffer.setPixel(x, y, color);
                x += stepX;
                y += stepY;
            }
        } else {
            // Standard Bresenham algorithm with proper handling of directions
            var err: i32 = 0;

            if (dx > dy) {
                // x-dominant case
                err = @divFloor(dx, 2);

                while (x != endX + stepX) {
                    if (x >= 0 and x < self.width and y >= 0 and y < self.height) {
                        self.frameBuffer.setPixel(x, y, color);
                    }

                    err -= dy;
                    if (err < 0) {
                        y += stepY;
                        err += dx;
                    }

                    x += stepX;
                }
            } else {
                // y-dominant case
                err = @divFloor(dy, 2);

                while (y != endY + stepY) {
                    if (x >= 0 and x < self.width and y >= 0 and y < self.height) {
                        self.frameBuffer.setPixel(x, y, color);
                    }

                    err -= dx;
                    if (err < 0) {
                        x += stepX;
                        err += dy;
                    }

                    y += stepY;
                }
            }
        }
    }

    pub fn drawLine(self: *Renderer, line: Line, color: Color) void {
        self.drawLinePts(line.start, line.end, color);
    }

    // MARK: Circle drawing
    fn drawHorizontalScanLine(self: *Renderer, y: i32, startx: i32, endx: i32, color: Color) void {
        if (y < 0 or y >= self.height) return;

        const clippedStart = @max(0, startx);
        const clippedEnd = @min(self.width - 1, endx);

        var x = clippedStart;
        while (x <= clippedEnd) : (x += 1) {
            self.frameBuffer.setPixel(x, y, color);
        }
    }

    fn drawCircleFilled(self: *Renderer, circle: Circle, color: Color) void {
        const center = self.gameToScreenCoordsFromPoint(circle.origin);
        const edgeScreen = self.gameToScreenCoordsFromXY(circle.origin.x + circle.radius, circle.origin.y);
        const screenRadius: i32 = edgeScreen.x - center.x;

        var x: i32 = 0;
        var y: i32 = screenRadius;
        var d: i32 = 1 - screenRadius;

        self.drawHorizontalScanLine(center.y, center.x - screenRadius, center.x + screenRadius, color);

        while (x <= y) {
            if (d < 0) {
                d += 2 * x + 3;
            } else {
                d += 2 * (x - y) + 5;
                y -= 1;
            }
            x += 1;
            self.drawHorizontalScanLine(center.y + y, center.x - x, center.x + x, color);
            self.drawHorizontalScanLine(center.y - y, center.x - x, center.x + x, color);
            self.drawHorizontalScanLine(center.y + x, center.x - y, center.x + y, color);
            self.drawHorizontalScanLine(center.y - x, center.x - y, center.x + y, color);
        }
    }

    inline fn plotCirclePoint(self: *Renderer, x: i32, y: i32, color: Color) void {
        if (x >= 0 and x < self.width and y >= 0 and y < self.height) {
            self.frameBuffer.setPixel(x, y, color);
        }
    }

    fn plotCirclePoints(self: *Renderer, center: ScreenPoint, x: i32, y: i32, color: Color) void {
        self.plotCirclePoint(center.x + x, center.y + y, color);
        self.plotCirclePoint(center.x - x, center.y + y, color);
        self.plotCirclePoint(center.x + x, center.y - y, color);
        self.plotCirclePoint(center.x - x, center.y - y, color);
        self.plotCirclePoint(center.x + y, center.y + x, color);
        self.plotCirclePoint(center.x - y, center.y + x, color);
        self.plotCirclePoint(center.x + y, center.y - x, color);
        self.plotCirclePoint(center.x - y, center.y - x, color);
    }

    fn drawCircleOutline(self: *Renderer, circle: Circle, color: Color) void {
        const center = self.gameToScreenCoordsFromPoint(circle.origin);
        const edgeScreen = self.gameToScreenCoordsFromXY(circle.origin.x + circle.radius, circle.origin.y);
        const screenRadius: i32 = edgeScreen.x - center.x;

        var x: i32 = 0;
        var y: i32 = screenRadius;
        var d: i32 = 1 - screenRadius;

        while (x <= y) {
            self.plotCirclePoints(center, x, y, color);

            if (d < 0) {
                d += 2 * x + 3;
            } else {
                d += 2 * (x - y) + 5;
                y -= 1;
            }
            x += 1;
        }
    }

    pub fn drawCircle(self: *Renderer, circle: Circle, fillColor: ?Color, outlineColor: ?Color) void {
        if (fillColor != null) {
            self.drawCircleFilled(circle, fillColor.?);
        }
        if (outlineColor != null) {
            self.drawCircleOutline(circle, outlineColor.?);
        }
    }

    // MARK: Rectangles
    fn drawRectFilled(self: *Renderer, rect: Rectangle, color: Color) void {
        const corners = rect.getCorners();

        const topLeft = self.gameToScreenCoordsFromPoint(corners[0]);
        const bottomRight = self.gameToScreenCoordsFromPoint(corners[2]);

        std.debug.assert(topLeft.x <= bottomRight.x);
        std.debug.assert(topLeft.y <= bottomRight.y);

        const startX = @max(0, topLeft.x);
        const endX = @min(self.width, bottomRight.x);
        const startY = @max(0, topLeft.y);
        const endY = @min(self.height, bottomRight.y);

        if (startX > self.width or endX < 0 or startY > self.height or endY < 0) return;

        var y = startY;
        while (y <= endY) : (y += 1) {
            var x = startX;
            while (x <= endX) : (x += 1) {
                self.frameBuffer.setPixel(x, y, color);
            }
        }
    }

    fn drawRectOutline(self: *Renderer, rect: Rectangle, color: Color) void {
        const corners = rect.getCorners();
        for (0..4) |i| {
            const start = corners[i];
            const end = corners[(i + 1) % 4];
            self.drawLinePts(start, end, color);
        }
    }

    pub fn drawRectangle(self: *Renderer, rect: Rectangle, fillColor: ?Color, outlineColor: ?Color) void {
        if (fillColor) |fc| {
            self.drawRectFilled(rect, fc);
        }
        if (outlineColor) |oc| {
            self.drawRectOutline(rect, oc);
        }
    }
};

// MARK: Types
const ScreenPoint = struct {
    x: i32,
    y: i32,

    fn isSamePoint(self: *const ScreenPoint, otherPoint: ScreenPoint) bool {
        return self.x == otherPoint.x and self.y == otherPoint.y;
    }
};
//
// pub const Transform = struct {
//     position: Point,
//     rotation: f32,
//     scale: f32,
// };
