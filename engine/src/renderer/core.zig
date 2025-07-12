const std = @import("std");
const rTypes = @import("types.zig");
const trans = @import("transformation.zig");
const ecs = @import("ecs");

const Circle = rTypes.Circle;
const Color = rTypes.Color;
const Ellipse = rTypes.Ellipse;
const FrameBuffer = rTypes.FrameBuffer;
const Line = rTypes.Line;
const Point = rTypes.GamePoint;
const Polygon = rTypes.Polygon;
const Rectangle = rTypes.Rectangle;
const ScreenPoint = rTypes.ScreenPoint;
const ShapeData = rTypes.ShapeData;
const Transform = rTypes.Transform;
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
        return trans.gameToScreen(self, p);
    }

    pub fn screenToGame(self: *const Renderer, sp: ScreenPoint) Point {
        return trans.screenToGame(self, sp);
    }

    pub fn drawShape(
        self: *Renderer,
        shape: ShapeData,
        transform: ?Transform,
    ) void {
        if (transform) |xform| {
            switch (shape) {
                .Circle => |circle| {
                    self.drawCircleWithTransform(circle, xform);
                },
                .Ellipse => |ellipse| {
                    _ = ellipse;
                    std.debug.panic("Ellipse has not been implemented yet!!\n", .{});
                },
                .Line => |line| {
                    self.drawLineWithTransform(line, xform);
                },
                .Rectangle => |rect| {
                    self.drawRectangleWithTransform(rect, xform);
                },
                .Triangle => |tri| {
                    self.drawTriangleWithTransform(tri, xform);
                },
                .Polygon => |poly| {
                    self.drawPolygonWithTransform(poly, xform);
                },
            }
        } else {
            switch (shape) {
                .Circle => |circle| {
                    self.drawCircle(circle);
                },
                .Ellipse => |ellipse| {
                    _ = ellipse;
                    std.debug.panic("TODO: Ellipse has not been implemented yet!!\n", .{});
                },
                .Line => |line| {
                    self.drawLine(line.start, line.end, line.color);
                },
                .Rectangle => |rect| {
                    self.drawRectangle(rect, null);
                },
                .Triangle => |tri| {
                    self.drawTriangle(tri, null);
                },
                .Polygon => |poly| {
                    self.drawPolygon(poly, null);
                },
            }
        }
    }

    // MARK: Internal drawing helpers
    fn scalePt(point: Point, scale: f32) Point {
        return Point.init(point.x * scale, point.y * scale);
    }

    fn rotatePt(point: Point, rot: f32) Point {
        const cos_r = std.math.cos(rot);
        const sin_r = std.math.sin(rot);
        const oldX = point.x;
        return Point.init(
            oldX * cos_r - point.y * sin_r,
            oldX * sin_r + point.y * cos_r,
        );
    }

    fn movePt(point: Point, pos: Point) Point {
        return Point.init(
            point.x + pos.x,
            point.y + pos.y,
        );
    }

    fn transformPoint(point: Point, transform: Transform) Point {
        var result = point;

        if (transform.scale) |s| result = scalePt(result, s);

        if (transform.rotation) |rot| result = rotatePt(result, rot);

        if (transform.offset) |pos| result = movePt(result, pos);

        return result;
    }

    fn drawOutlineWithTransform(renderer: *Renderer, pts: []const Point, transform: ?Transform, color: Color) void {
        if (transform) |xform| {
            const len = pts.len;
            switch (len) {
                0 => return,
                1 => drawPoint(renderer, transformPoint(pts[0], xform), color),
                2 => drawLineWithTransform(renderer, Line{ .start = pts[0], .end = pts[1], .color = color }, xform),
                else => {
                    // draw them all
                    for (0..len) |i| {
                        const start = pts[i];
                        const end = pts[(i + 1) % len];
                        drawLineWithTransform(renderer, Line{ .start = start, .end = end, .color = color }, xform);
                    }
                },
            }
        } else {
            drawOutline(renderer, pts, color);
        }
    }

    fn drawOutline(renderer: *Renderer, pts: []const Point, color: Color) void {
        const len = pts.len;
        switch (len) {
            0 => return,
            1 => drawPoint(renderer, pts[0], color),
            2 => drawLine(renderer, pts[0], pts[1], color),
            else => {
                // draw them all
                for (0..len) |i| {
                    const start = pts[i];
                    const end = pts[(i + 1) % len];
                    drawLine(renderer, start, end, color);
                }
            },
        }
    }

    // MARK: Point
    fn drawPoint(renderer: *Renderer, point: Point, color: ?Color) void {
        const c = if (color != null) color.? else return;

        const screenPos = renderer.gameToScreen(point);

        if (screenPos.x < 0 or screenPos.x >= renderer.width or
            screenPos.y < 0 or screenPos.y >= renderer.height)
            return;

        renderer.frameBuffer.setPixel(screenPos.x, screenPos.y, c);
    }

    // MARK: Lines
    fn drawLineWithTransform(renderer: *Renderer, line: Line, xform: Transform) void {
        const start = transformPoint(line.start, xform);
        const end = transformPoint(line.end, xform);
        renderer.drawLine(start, end, line.color);
    }

    fn drawLine(renderer: *Renderer, start: Point, end: Point, color: ?Color) void {
        const c = if (color != null) color.? else return;

        const screenStart = renderer.gameToScreen(start);
        const screenEnd = renderer.gameToScreen(end);

        if (screenStart.isSamePoint(screenEnd)) return drawPoint(renderer, start, c);
        var x = screenStart.x;
        var y = screenStart.y;
        const endX = screenEnd.x;
        const endY = screenEnd.y;

        var dx = screenEnd.x - screenStart.x;
        var dy = screenEnd.y - screenStart.y;

        const stepX: i32 = if (dx < 0) -1 else 1;
        const stepY: i32 = if (dy < 0) -1 else 1;

        dx = @intCast(@abs(dx));
        dy = @intCast(@abs(dy));

        if (dx == 0) {
            // Handle vertical case
            while (y != endY) : (y += stepY) {
                renderer.frameBuffer.setPixel(x, y, c);
            }
        } else if (dy == 0) {
            // Handle horizontal case
            while (x != endX) : (x += stepX) {
                renderer.frameBuffer.setPixel(x, y, c);
            }
        } else if (dx == dy) {
            // Handle diagonal case
            while (x != endX) {
                renderer.frameBuffer.setPixel(x, y, c);
                x += stepX;
                y += stepY;
            }
        } else {
            // Standard Bresenham algorithm with proper handling of directions
            var err: i32 = 0;

            if (dx > dy) {
                err = @divFloor(dx, 2);

                while (x != endX + stepX) {
                    if (x >= 0 and x < renderer.width and y >= 0 and y < renderer.height) {
                        renderer.frameBuffer.setPixel(x, y, c);
                    }

                    err -= dy;
                    if (err < 0) {
                        y += stepY;
                        err += dx;
                    }

                    x += stepX;
                }
            } else {
                err = @divFloor(dy, 2);

                while (y != endY + stepY) {
                    if (x >= 0 and x < renderer.width and y >= 0 and y < renderer.height) {
                        renderer.frameBuffer.setPixel(x, y, c);
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
    fn drawCircleWithTransform(renderer: *Renderer, circle: Circle, xform: Transform) void {
        const newOrigin = transformPoint(circle.origin, xform);
        const newRadius = if (xform.scale) |scale| circle.radius * scale else circle.radius;
        const newCircle = Circle{
            .origin = newOrigin,
            .radius = newRadius,
            .fillColor = circle.fillColor,
            .outlineColor = circle.outlineColor,
        };
        drawCircle(renderer, newCircle);
    }

    fn drawCircle(renderer: *Renderer, circle: Circle) void {
        if (circle.fillColor) |fc| {
            drawCircleFilled(renderer, circle, fc);
        }
        if (circle.outlineColor) |oc| {
            drawCircleOutline(renderer, circle, oc);
        }
    }

    fn drawHorizontalScanLineF32(renderer: *Renderer, y: f32, startx: f32, endx: f32, color: Color) void {
        const start = renderer.gameToScreenCoordsFromPoint(startx, y);
        const end = renderer.gameToScreenFromXY(endx, y);

        renderer.drawHorizontalScanLineInt(start.y, start.x, end.x, color);
    }

    fn drawHorizontalScanLineInt(renderer: *Renderer, y: i32, startx: i32, endx: i32, color: Color) void {
        if (y < 0 or y >= renderer.height) return;

        const clippedStart = @max(0, startx);
        const clippedEnd = @min(renderer.width - 1, endx);

        var x = clippedStart;
        while (x <= clippedEnd) : (x += 1) {
            renderer.frameBuffer.setPixel(x, y, color);
        }
    }

    fn drawCircleFilled(renderer: *Renderer, circle: Circle, color: Color) void {
        const center = renderer.gameToScreen(circle.origin);
        const edge = Point.init(circle.origin.x + circle.radius, circle.origin.y);
        const edgeScreen = renderer.gameToScreen(edge);
        const screenRadius: i32 = edgeScreen.x - center.x;

        var x: i32 = 0;
        var y: i32 = screenRadius;
        var d: i32 = 1 - screenRadius;

        drawHorizontalScanLineInt(renderer, center.y, center.x - screenRadius, center.x + screenRadius, color);

        while (x <= y) {
            if (d < 0) {
                d += 2 * x + 3;
            } else {
                d += 2 * (x - y) + 5;
                y -= 1;
            }
            x += 1;
            drawHorizontalScanLineInt(renderer, center.y + y, center.x - x, center.x + x, color);
            drawHorizontalScanLineInt(renderer, center.y - y, center.x - x, center.x + x, color);
            drawHorizontalScanLineInt(renderer, center.y + x, center.x - y, center.x + y, color);
            drawHorizontalScanLineInt(renderer, center.y - x, center.x - y, center.x + y, color);
        }
    }

    inline fn plotCirclePoint(renderer: *Renderer, x: i32, y: i32, color: Color) void {
        if (x >= 0 and x < renderer.width and y >= 0 and y < renderer.height) {
            renderer.frameBuffer.setPixel(x, y, color);
        }
    }

    fn plotCirclePoints(renderer: *Renderer, center: ScreenPoint, x: i32, y: i32, color: Color) void {
        plotCirclePoint(renderer, center.x + x, center.y + y, color);
        plotCirclePoint(renderer, center.x - x, center.y + y, color);
        plotCirclePoint(renderer, center.x + x, center.y - y, color);
        plotCirclePoint(renderer, center.x - x, center.y - y, color);
        plotCirclePoint(renderer, center.x + y, center.y + x, color);
        plotCirclePoint(renderer, center.x - y, center.y + x, color);
        plotCirclePoint(renderer, center.x + y, center.y - x, color);
        plotCirclePoint(renderer, center.x - y, center.y - x, color);
    }

    fn drawCircleOutline(renderer: *Renderer, circle: Circle, color: Color) void {
        const center = renderer.gameToScreen(circle.origin);
        const edge = Point.init(circle.origin.x + circle.radius, circle.origin.y);
        const edgeScreen = renderer.gameToScreen(edge);
        const screenRadius: i32 = edgeScreen.x - center.x;

        var x: i32 = 0;
        var y: i32 = screenRadius;
        var d: i32 = 1 - screenRadius;

        while (x <= y) {
            plotCirclePoints(renderer, center, x, y, color);

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
    fn drawRectangleWithTransform(renderer: *Renderer, rect: Rectangle, transform: Transform) void {
        // const newCenter = transformPoint(rect.center, transform);
        const newHalfWidth = if (transform.scale) |scale| rect.halfWidth * scale else rect.halfWidth;
        const newHalfHeight = if (transform.scale) |scale| rect.halfHeight * scale else rect.halfHeight;

        const newRect = Rectangle{
            .center = rect.center,
            .halfWidth = newHalfWidth,
            .halfHeight = newHalfHeight,
            .fillColor = rect.fillColor,
            .outlineColor = rect.outlineColor,
        };
        renderer.drawRectangle(newRect, transform);
    }

    fn drawRectangle(renderer: *Renderer, rect: Rectangle, transform: ?Transform) void {
        if (rect.fillColor) |_| {
            drawRectFilled(renderer, rect, transform);
        }
        if (rect.outlineColor) |_| {
            drawRectOutline(renderer, rect, transform);
        }
    }

    fn drawRectFilled(renderer: *Renderer, rect: Rectangle, transform: ?Transform) void {
        const corners = rect.getCorners();

        var c0 = corners[0];
        var c1 = corners[1];
        var c2 = corners[2];
        var c3 = corners[3];
        if (transform) |xform| {
            c0 = transformPoint(c0, xform);
            c1 = transformPoint(c1, xform);
            c2 = transformPoint(c2, xform);
            c3 = transformPoint(c3, xform);

            if (xform.rotation) |_| {
                var verts1: [3]Point = .{ c0, c1, c2 };
                std.mem.sort(Point, &verts1, {}, sortPointByY);
                var verts2: [3]Point = .{ c0, c2, c3 };
                std.mem.sort(Point, &verts2, {}, sortPointByY);

                const tri1 = Triangle{
                    .vertices = verts1,
                    .fillColor = rect.fillColor.?,
                    .outlineColor = null,
                };
                const tri2 = Triangle{
                    .vertices = verts2,
                    .fillColor = rect.fillColor.?,
                    .outlineColor = null,
                };

                drawTriangle(renderer, tri1, null);
                drawTriangle(renderer, tri2, null);
                return;
            }
        }

        const topLeft = renderer.gameToScreen(c0);
        const bottomRight = renderer.gameToScreen(c2);

        std.debug.assert(topLeft.x <= bottomRight.x);
        std.debug.assert(topLeft.y <= bottomRight.y);

        const startX = @max(0, topLeft.x);
        const endX = @min(renderer.width, bottomRight.x);
        const startY = @max(0, topLeft.y);
        const endY = @min(renderer.height, bottomRight.y);

        if (startX > renderer.width or endX < 0 or startY > renderer.height or endY < 0) return;

        var y = startY;
        while (y <= endY) : (y += 1) {
            var x = startX;
            while (x <= endX) : (x += 1) {
                renderer.frameBuffer.setPixel(x, y, rect.fillColor.?);
            }
        }
    }

    fn drawRectOutline(renderer: *Renderer, rect: Rectangle, transform: ?Transform) void {
        const corners = rect.getCorners();

        const c0 = if (transform) |xform| transformPoint(corners[0], xform) else corners[0];
        const c1 = if (transform) |xform| transformPoint(corners[1], xform) else corners[1];
        const c2 = if (transform) |xform| transformPoint(corners[2], xform) else corners[2];
        const c3 = if (transform) |xform| transformPoint(corners[3], xform) else corners[3];
        const xformexCorners: [4]Point = .{ c0, c1, c2, c3 };

        for (0..4) |i| {
            const start = xformexCorners[i];
            const end = xformexCorners[(i + 1) % 4];
            drawLine(renderer, start, end, rect.outlineColor);
        }
    }

    // MARK: Triangle
    fn drawTriangleWithTransform(renderer: *Renderer, tri: Triangle, xform: Transform) void {
        drawTriangle(renderer, tri, xform);
    }

    fn drawTriangle(renderer: *Renderer, tri: Triangle, transform: ?Transform) void {
        if (tri.fillColor) |fc| {
            drawTriangleFilled(renderer, &tri.vertices, transform, fc);
        }
        if (tri.outlineColor) |oc| {
            drawOutlineWithTransform(renderer, &tri.vertices, transform, oc);
        }
    }

    fn drawTriangleFilled(renderer: *Renderer, verts: []const Point, transform: ?Transform, color: Color) void {
        std.debug.assert(verts.len == 3);

        var v0 = if (transform) |xform| transformPoint(verts[0], xform) else verts[0];
        var v1 = if (transform) |xform| transformPoint(verts[1], xform) else verts[1];
        var v2 = if (transform) |xform| transformPoint(verts[2], xform) else verts[2];

        if (transform) |xform| {
            if (xform.rotation) |_| {
                var newVerts: [3]Point = .{ v0, v1, v2 };
                std.mem.sort(Point, &newVerts, {}, sortPointByY);
                v0 = newVerts[0];
                v1 = newVerts[1];
                v2 = newVerts[2];
            }
        }

        if (v0.y == v1.y) {
            drawFlatTopTriangle(renderer, v0, v1, v2, color);
        } else if (v1.y == v2.y) {
            drawFlatBottomTriangle(renderer, v0, v1, v2, color);
        } else {
            const factor = (v1.y - v0.y) / (v2.y - v0.y);
            const v3 = Point{ .x = v0.x + factor * (v2.x - v0.x), .y = v1.y };

            drawFlatBottomTriangle(renderer, v0, v1, v3, color);
            drawFlatTopTriangle(renderer, v1, v3, v2, color);
        }
    }

    fn drawFlatTopTriangle(renderer: *Renderer, v1: Point, v2: Point, v3: Point, color: Color) void {
        std.debug.assert(v1.y == v2.y);

        const topLeft = if (v1.x < v2.x) v1 else v2;
        const topRight = if (v1.x < v2.x) v2 else v1;

        const screenTopLeft = renderer.gameToScreen(topLeft);
        const screenTopRight = renderer.gameToScreen(topRight);
        const screenBottom = renderer.gameToScreen(v3);

        const leftYDist = screenBottom.y - screenTopLeft.y;
        const rightYDist = screenBottom.y - screenTopRight.y;

        const leftXDist = screenTopLeft.x - screenBottom.x;
        const rightXDist = screenTopRight.x - screenBottom.x;

        const leftXInc: f32 = @as(f32, @floatFromInt(leftXDist)) / @as(f32, @floatFromInt(leftYDist));
        const rightXInc: f32 = @as(f32, @floatFromInt(rightXDist)) / @as(f32, @floatFromInt(rightYDist));

        var currY = screenBottom.y;

        var leftX: f32 = @floatFromInt(screenBottom.x);
        var rightX: f32 = @floatFromInt(screenBottom.x);

        while (currY >= screenTopLeft.y) : (currY -= 1) {
            const leftXInt: i32 = @intFromFloat(leftX);
            const rightXInt: i32 = @intFromFloat(rightX);

            drawHorizontalScanLineInt(renderer, currY, leftXInt, rightXInt, color);

            leftX += leftXInc;
            rightX += rightXInc;
        }
    }

    fn drawFlatBottomTriangle(renderer: *Renderer, v1: Point, v2: Point, v3: Point, color: Color) void {
        std.debug.assert(v2.y == v3.y);

        const botLeft = if (v2.x < v3.x) v2 else v3;
        const botRight = if (v2.x < v3.x) v3 else v2;

        const screenBotLeft = renderer.gameToScreen(botLeft);
        const screenBotRight = renderer.gameToScreen(botRight);
        const screenTop = renderer.gameToScreen(v1);

        const leftYDist = screenBotLeft.y - screenTop.y; // This should be positive
        const rightYDist = screenBotRight.y - screenTop.y; // This should be positive

        const leftXDist = screenBotLeft.x - screenTop.x;
        const rightXDist = screenBotRight.x - screenTop.x;

        const leftXInc: f32 = @as(f32, @floatFromInt(leftXDist)) / @as(f32, @floatFromInt(leftYDist));
        const rightXInc: f32 = @as(f32, @floatFromInt(rightXDist)) / @as(f32, @floatFromInt(rightYDist));

        var currY = screenTop.y;
        var leftX: f32 = @floatFromInt(screenTop.x);
        var rightX: f32 = @floatFromInt(screenTop.x);

        while (currY <= screenBotLeft.y) : (currY += 1) {
            const leftXInt: i32 = @intFromFloat(leftX);
            const rightXInt: i32 = @intFromFloat(rightX);

            const drawLeft = @min(leftXInt, rightXInt);
            const drawRight = @max(leftXInt, rightXInt);

            drawHorizontalScanLineInt(renderer, currY, drawLeft, drawRight, color);

            leftX += leftXInc;
            rightX += rightXInc;
        }
    }

    // MARK: Polygon
    fn drawPolygonWithTransform(renderer: *Renderer, poly: Polygon, xform: Transform) void {
        drawPolygon(renderer, poly, xform);
    }

    fn drawPolygon(renderer: *Renderer, poly: Polygon, transform: ?Transform) void {
        if (poly.fillColor) |_| {
            drawPolygonFilled(renderer, poly, transform);
        }
        if (poly.outlineColor) |oc| {
            drawOutlineWithTransform(renderer, poly.vertices, transform, oc);
        }
    }

    fn drawPolygonOutline(renderer: *Renderer, poly: Polygon, transform: ?Transform) void {
        if (transform) |xform| {
            return drawPolygonOutline(renderer, poly, xform, poly.outlineColor);
        }
        return drawOutline(renderer, poly.verts, poly.outlineColor);
    }

    fn drawPolygonFilled(renderer: *Renderer, poly: Polygon, transform: ?Transform) void {
        var sortedVerts: [3]Point = undefined;
        var v1: Point = undefined;
        var v2: Point = undefined;

        const center = if (transform) |xform| transformPoint(poly.center, xform) else poly.center;
        for (0..poly.vertices.len) |i| {
            v1 = if (transform) |xform| transformPoint(poly.vertices[i], xform) else poly.vertices[i];
            const idx = (i + 1) % poly.vertices.len;
            v2 = if (transform) |xform| transformPoint(poly.vertices[idx], xform) else poly.vertices[idx];
            sortedVerts = .{ center, v1, v2 };
            std.mem.sort(Point, &sortedVerts, {}, sortPointByY);
            drawTriangleFilled(renderer, &sortedVerts, null, poly.fillColor.?);
        }
    }

    fn sortPointByY(context: void, a: Point, b: Point) bool {
        _ = context;
        return a.y > b.y;
    }
};
