const std = @import("std");

const FrameBuffer = @import("frameBuffer.zig").FrameBuffer;

const prim = @import("primitives.zig");
const Circle = prim.Circle;
const Color = prim.Color;
const Ellipse = prim.Ellipse;
const Line = prim.Line;
const Point = prim.Point;
const Rectangle = prim.Rectangle;
const Triangle = prim.Triangle;
const Polygon = prim.Polygon;

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

    // MARK: Drawing
    fn gameToScreenCoordsFromXY(self: *const Renderer, x: f32, y: f32) ScreenPoint {
        // const fw: f32 = @floatFromInt(self.width);
        // const fh: f32 = @floatFromInt(self.height);
        const screenX: i32 = @intFromFloat((x + 1.0) * 0.5 * self.fw);
        const screenY: i32 = @intFromFloat((1.0 - y) * 0.5 * self.fh);

        return .{ .x = screenX, .y = screenY };
    }

    fn gameToScreenCoordsX(self: *const Renderer, x: f32) i32 {
        const fw: f32 = @floatFromInt(self.width);
        return @intFromFloat((x + 1.0) * 0.5 * fw);
    }
    fn gameToScreenCoordsY(self: *const Renderer, y: f32) i32 {
        const fh: f32 = @floatFromInt(self.height);
        return @intFromFloat((1.0 - y) * 0.5 * fh);
    }

    inline fn gameToScreenCoordsFromPoint(self: *const Renderer, point: Point) ScreenPoint {
        return self.gameToScreenCoordsFromXY(point.x, point.y);
    }

    pub fn getRawFrameBuffer(self: *const Renderer) []const Color {
        return self.frameBuffer.frontBuffer;
    }

    pub fn drawOutline(self: *Renderer, pts: []const Point, color: Color) void {
        const len = pts.len;
        switch (len) {
            0 => return,
            1 => self.drawPoint(pts[0], color),
            2 => self.drawLine(pts[0], pts[1], color),
            else => {
                // draw them all
                for (0..len) |i| {
                    const start = pts[i];
                    const end = pts[(i + 1) % len];
                    self.drawLine(start, end, color);
                }
            },
        }
    }

    // MARK: Point
    pub fn drawPoint(self: *Renderer, point: Point, color: ?Color) void {
        const c = if (color != null) color.? else return;

        const screenPos = self.gameToScreenCoordsFromPoint(point);

        if (screenPos.x < 0 or screenPos.x >= self.width or
            screenPos.y < 0 or screenPos.y >= self.height)
            return;

        self.frameBuffer.setPixel(screenPos.x, screenPos.y, c);
    }

    // MARK: Lines
    /// Draws a line between two points in game space.
    ///
    /// This function converts game coordinates (-1,1) to screen coordinates,
    /// uses Bresenham's algorithm for efficient line drawing, and handles
    /// clipping for lines that extend beyond the screen boundaries.
    ///
    /// Parameters:
    ///     self: Pointer to the Renderer instance
    ///     start: Point structure containing a start point in game space coordinates
    ///     end: Point structure containing an end point in game space coordinates
    ///     color: Optional color for the line. If null, no line will be drawn
    ///
    /// Example:
    ///     // Draw a horizontal line across the screen in cyan
    ///         const start = Point{ .x = -1.0, .y = 0.0 },
    ///         const end = Point{ .x = 1.0, .y = 0.0 },
    ///     renderer.drawLine(start, end, Color.init(0, 1, 1, 1));
    ///
    /// Notes:
    ///     - Coordinates outside the (-1,1) range will be clipped to screen boundaries
    ///     - Special cases for horizontal, vertical, and diagonal lines are optimized
    ///     - If start and end points are the same, a single point will be drawn
    pub fn drawLine(self: *Renderer, start: Point, end: Point, color: ?Color) void {
        const c = if (color != null) color.? else return;

        const screenStart = self.gameToScreenCoordsFromPoint(start);
        const screenEnd = self.gameToScreenCoordsFromPoint(end);

        if (screenStart.isSamePoint(screenEnd)) return self.drawPoint(start, c);
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
                self.frameBuffer.setPixel(x, y, c);
            }
        } else if (dy == 0) {
            // Handle horizontal case
            while (x != endX) : (x += stepX) {
                self.frameBuffer.setPixel(x, y, c);
            }
        } else if (dx == dy) {
            // Handle diagonal case
            while (x != endX) {
                self.frameBuffer.setPixel(x, y, c);
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
                        self.frameBuffer.setPixel(x, y, c);
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
                        self.frameBuffer.setPixel(x, y, c);
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

    // MARK: Circle drawing
    /// Draws a circle in game space with optional fill and outline colors.
    ///
    /// This function renders a circle using an efficient implementation of the
    /// midpoint circle algorithm. The circle is defined by its origin point and radius
    /// in game space coordinates (-1,1). Both filled and outlined versions can be
    /// drawn, depending on which color parameters are provided.
    ///
    /// Parameters:
    ///     self: Pointer to the Renderer instance
    ///     circle: Circle structure containing origin point and radius in game space
    ///     fillColor: Optional color for filling the circle. If null, no fill is drawn
    ///     outlineColor: Optional color for the circle outline. If null, no outline is drawn
    ///
    /// Example:
    ///     // Draw a red filled circle with a yellow outline at the center of the screen
    ///     const circle = Circle{
    ///         .origin = Point{ .x = 0.0, .y = 0.0 },
    ///         .radius = 0.5,
    ///     };
    ///     renderer.drawCircle(circle, Color.init(1, 0, 0, 1), Color.init(1, 1, 0, 1));
    ///
    /// Notes:
    ///     - If both fillColor and outlineColor are null, nothing will be drawn
    ///     - The circle is automatically clipped if it extends beyond screen boundaries
    ///     - For small circles, the algorithm automatically simplifies to improve performance
    pub fn drawCircle(self: *Renderer, circle: Circle, fill: ?Color, outline: ?Color) void {
        if (fill) |fc| {
            self.drawCircleFilled(circle, fc);
        }
        if (outline) |oc| {
            self.drawCircleOutline(circle, oc);
        }
    }

    fn drawHorizontalScanLineF32(self: *Renderer, y: f32, startx: f32, endx: f32, color: Color) void {
        const start = self.gameToScreenCoordsFromPoint(startx, y);
        const end = self.gameToScreenCoordsFromXY(endx, y);

        self.drawHorizontalScanLineInt(start.y, start.x, end.x, color);
    }

    fn drawHorizontalScanLineInt(self: *Renderer, y: i32, startx: i32, endx: i32, color: Color) void {
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

        self.drawHorizontalScanLineInt(center.y, center.x - screenRadius, center.x + screenRadius, color);

        while (x <= y) {
            if (d < 0) {
                d += 2 * x + 3;
            } else {
                d += 2 * (x - y) + 5;
                y -= 1;
            }
            x += 1;
            self.drawHorizontalScanLineInt(center.y + y, center.x - x, center.x + x, color);
            self.drawHorizontalScanLineInt(center.y - y, center.x - x, center.x + x, color);
            self.drawHorizontalScanLineInt(center.y + x, center.x - y, center.x + y, color);
            self.drawHorizontalScanLineInt(center.y - x, center.x - y, center.x + y, color);
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

    // MARK: Rectangles
    /// Draws a rectangle in game space with optional fill and outline colors.
    ///
    /// This function renders a rectangle defined by its center point, half-width,
    /// and half-height in game space coordinates (-1,1). The rectangle can be
    /// filled, outlined, or both depending on which color parameters are provided.
    ///
    /// Parameters:
    ///     self: Pointer to the Renderer instance
    ///     rect: Rectangle structure containing center point, half-width, and half-height
    ///     fillColor: Optional color for filling the rectangle. If null, no fill is drawn
    ///     outlineColor: Optional color for the rectangle outline. If null, no outline is drawn
    ///
    /// Example:
    ///     // Draw a blue filled rectangle with a white outline
    ///     const rect = Rectangle.initFromCenter(
    ///         Point{ .x = 0.0, .y = 0.0 },
    ///         0.8,  // width
    ///         0.6   // height
    ///     );
    ///     renderer.drawRectangle(rect, Color.init(0, 0, 1, 1), Color.init(1, 1, 1, 1));
    ///
    ///     // Draw just the outline of a rectangle
    ///     const outlineOnly = Rectangle.initSquare(Point{ .x = 0.5, .y = 0.5 }, 0.2);
    ///     renderer.drawRectangle(outlineOnly, null, Color.init(1, 1, 0, 1));
    ///
    /// Notes:
    ///     - If both fillColor and outlineColor are null, nothing will be drawn
    ///     - The rectangle is automatically clipped if it extends beyond screen boundaries
    ///     - Helper functions like Rectangle.initSquare() and Rectangle.initFromTopLeft()
    ///       can be used to create rectangles with different initialization parameters
    pub fn drawRectangle(self: *Renderer, rect: Rectangle, fill: ?Color, outline: ?Color) void {
        if (fill) |fc| {
            self.drawRectFilled(rect, fc);
        }
        if (outline) |oc| {
            self.drawRectOutline(rect, oc);
        }
    }
    fn drawRectFilled(self: *Renderer, rect: Rectangle, color: Color) void {
        // TODO: can this be optimized? (setmem style?)
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
            self.drawLine(start, end, color);
        }
    }

    // MARK: Triangle
    pub fn drawTriangle(self: *Renderer, tri: Triangle, fill: ?Color, outline: ?Color) void {
        if (fill) |fc| {
            self.drawTriangleFilled(tri.vertices, fc);
        }
        if (outline) |oc| {
            self.drawOutline(tri.vertices, oc);
        }
    }

    fn drawTriangleFilled(self: *Renderer, verts: []const Point, color: Color) void {
        // const sortedVerts = self.allocator.dupe(Point, verts) catch {
        // std.debug.print("Unable to sort vertices for drawing\n", .{});
        // return;
        // };
        // defer self.allocator.free(sortedVerts);
        // std.mem.sort(Point, sortedVerts, {}, sortPointByY);

        const v0 = verts[0];
        const v1 = verts[1];
        const v2 = verts[2];

        // const v0 = sortedVerts[0];
        // const v1 = sortedVerts[1];
        // const v2 = sortedVerts[2];

        if (v0.y == v1.y) {
            self.drawFlatTopTriangle(v0, v1, v2, color);
        } else if (v1.y == v2.y) {
            self.drawFlatBottomTriangle(v0, v1, v2, color);
        } else {
            const factor = (v1.y - v0.y) / (v2.y - v0.y);
            const v3 = Point{ .x = v0.x + factor * (v2.x - v0.x), .y = v1.y };

            self.drawFlatBottomTriangle(v0, v1, v3, color);
            self.drawFlatTopTriangle(v1, v3, v2, color);
        }
    }

    fn drawFlatTopTriangle(self: *Renderer, v1: Point, v2: Point, v3: Point, color: Color) void {
        std.debug.assert(v1.y == v2.y);

        const topLeft = if (v1.x < v2.x) v1 else v2;
        const topRight = if (v1.x < v2.x) v2 else v1;

        const screenTopLeftX = self.gameToScreenCoordsX(topLeft.x);
        const screenTopLeftY = self.gameToScreenCoordsY(topLeft.y);
        const screenTopRightX = self.gameToScreenCoordsX(topRight.x);
        const screenTopRightY = self.gameToScreenCoordsY(topRight.y);
        const screenBottomX = self.gameToScreenCoordsX(v3.x);
        const screenBottomY = self.gameToScreenCoordsY(v3.y);

        const leftYDist = screenBottomY - screenTopLeftY;
        const rightYDist = screenBottomY - screenTopRightY;

        const leftXDist = screenTopLeftX - screenBottomX;
        const rightXDist = screenTopRightX - screenBottomX;

        const leftXInc: f32 = @as(f32, @floatFromInt(leftXDist)) / @as(f32, @floatFromInt(leftYDist));
        const rightXInc: f32 = @as(f32, @floatFromInt(rightXDist)) / @as(f32, @floatFromInt(rightYDist));

        var currY = screenBottomY;

        var leftX: f32 = @floatFromInt(screenBottomX);
        var rightX: f32 = @floatFromInt(screenBottomX);

        while (currY >= screenTopLeftY) : (currY -= 1) {
            const leftXInt: i32 = @intFromFloat(leftX);
            const rightXInt: i32 = @intFromFloat(rightX);

            self.drawHorizontalScanLineInt(currY, leftXInt, rightXInt, color);

            leftX += leftXInc;
            rightX += rightXInc;
        }
    }
    fn drawFlatBottomTriangle(self: *Renderer, v1: Point, v2: Point, v3: Point, color: Color) void {
        std.debug.assert(v2.y == v3.y);

        const botLeft = if (v2.x < v3.x) v2 else v3;
        const botRight = if (v2.x < v3.x) v3 else v2;

        const screenBotLeftX = self.gameToScreenCoordsX(botLeft.x);
        const screenBotLeftY = self.gameToScreenCoordsY(botLeft.y);
        const screenBotRightX = self.gameToScreenCoordsX(botRight.x);
        const screenBotRightY = self.gameToScreenCoordsY(botRight.y);
        const screenTopX = self.gameToScreenCoordsX(v1.x);
        const screenTopY = self.gameToScreenCoordsY(v1.y);

        const leftYDist = screenBotLeftY - screenTopY; // This should be positive
        const rightYDist = screenBotRightY - screenTopY; // This should be positive

        const leftXDist = screenBotLeftX - screenTopX;
        const rightXDist = screenBotRightX - screenTopX;

        const leftXInc: f32 = @as(f32, @floatFromInt(leftXDist)) / @as(f32, @floatFromInt(leftYDist));
        const rightXInc: f32 = @as(f32, @floatFromInt(rightXDist)) / @as(f32, @floatFromInt(rightYDist));

        var currY = screenTopY;
        var leftX: f32 = @floatFromInt(screenTopX);
        var rightX: f32 = @floatFromInt(screenTopX);

        while (currY <= screenBotLeftY) : (currY += 1) {
            const leftXInt: i32 = @intFromFloat(leftX);
            const rightXInt: i32 = @intFromFloat(rightX);

            const drawLeft = @min(leftXInt, rightXInt);
            const drawRight = @max(leftXInt, rightXInt);

            self.drawHorizontalScanLineInt(currY, drawLeft, drawRight, color);

            leftX += leftXInc;
            rightX += rightXInc;
        }
    }

    // MARK: Polygon
    pub fn drawPolygon(self: *Renderer, poly: Polygon, fill: ?Color, outline: ?Color) void {
        switch (poly.vertices.len) {
            0, 1, 2 => {
                std.debug.print(
                    "[RENDERER] - drawPolygon: Not enough points (>3) for a polygon: {}\n",
                    .{poly.vertices.len},
                );
                return;
            },
            else => {
                if (fill) |fc| {
                    self.drawPolygonFilled(poly.vertices, poly.center, fc);
                }
                if (outline) |oc| {
                    self.drawOutline(poly.vertices, oc);
                }
            },
        }
    }

    fn drawPolygonOutline(self: *Renderer, verts: []const Point, color: Color) void {
        self.drawOutline(verts, color);
    }

    fn drawPolygonFilled(self: *Renderer, verts: []const Point, center: Point, color: Color) void {
        var sortedVerts: [3]Point = undefined;

        if (verts.len == 3) {
            self.drawTriangleFilled(verts, color);
            return;
        }
        for (0..verts.len) |i| {
            sortedVerts = .{ center, verts[i], verts[(i + 1) % verts.len] };
            std.mem.sort(Point, &sortedVerts, {}, sortPointByY);
            // self.drawOutline(&.{ center, verts[i], verts[(i + 1) % verts.len] }, Color.init(1, 1, 1, 1));
            self.drawTriangleFilled(&sortedVerts, color);
        }
    }
};

fn sortPointByY(context: void, a: Point, b: Point) bool {
    _ = context;
    return a.y > b.y;
}

// MARK: Types
const ScreenPoint = struct {
    x: i32,
    y: i32,

    fn isSamePoint(self: *const ScreenPoint, otherPoint: ScreenPoint) bool {
        return self.x == otherPoint.x and self.y == otherPoint.y;
    }
};
