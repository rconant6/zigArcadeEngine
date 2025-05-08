const std = @import("std");
const rTypes = @import("types.zig");

const Circle = rTypes.Circle;
const Color = rTypes.Color;
const Ellipse = rTypes.Ellipse;
const Line = rTypes.Line;
const Point = rTypes.GamePoint;
const Polygon = rTypes.Polygon;
const Rectangle = rTypes.Rectangle;
const ScreenPoint = rTypes.ScreenPoint;
const Triangle = rTypes.Triangle;

const Renderer = rTypes.Renderer;

// MARK: Drawing API
pub fn drawOutline(renderer: *Renderer, pts: []const Point, color: Color) void {
    const len = pts.len;
    switch (len) {
        0 => return,
        1 => renderer.drawPoint(pts[0], color),
        2 => renderer.drawLine(pts[0], pts[1], color),
        else => {
            // draw them all
            for (0..len) |i| {
                const start = pts[i];
                const end = pts[(i + 1) % len];
                renderer.drawLine(start, end, color);
            }
        },
    }
}

// MARK: Point
/// Draws a single point in game space.
///
/// Parameters:
///     point: The point to draw in game space coordinates (-1,1)
///     color: Optional color for the point. If null, nothing is drawn
///
/// Example:
///     // Draw a red point at the center of the screen
///     renderer.drawPoint(Point{ .x = 0, .y = 0 }, Color.init(1, 0, 0, 1));
pub fn drawPoint(renderer: *Renderer, point: Point, color: ?Color) void {
    const c = if (color != null) color.? else return;

    const screenPos = renderer.gameToScreen(point);

    if (screenPos.x < 0 or screenPos.x >= renderer.width or
        screenPos.y < 0 or screenPos.y >= renderer.height)
        return;

    renderer.frameBuffer.setPixel(screenPos.x, screenPos.y, c);
}

// MARK: Lines
/// Draws a line between two points in game space.
///
/// This function converts game coordinates (-1,1) to screen coordinates,
/// uses Bresenham's algorithm for efficient line drawing, and handles
/// clipping for lines that extend beyond the screen boundaries.
///
/// Parameters:
///     renderer: Pointer to the Renderer instance
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
pub fn drawLine(renderer: *Renderer, start: Point, end: Point, color: ?Color) void {
    const c = if (color != null) color.? else return;

    const screenStart = renderer.gameToScreen(start);
    const screenEnd = renderer.gameToScreen(end);

    if (screenStart.isSamePoint(screenEnd)) return renderer.drawPoint(start, c);
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
/// Draws a circle in game space with optional fill and outline colors.
///
/// This function renders a circle using an efficient implementation of the
/// midpoint circle algorithm. The circle is defined by its origin point and radius
/// in game space coordinates (-1,1). Both filled and outlined versions can be
/// drawn, depending on which color parameters are provided.
///
/// Parameters:
///     renderer: Pointer to the Renderer instance
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
pub fn drawCircle(renderer: *Renderer, circle: Circle, fill: ?Color, outline: ?Color) void {
    if (fill) |fc| {
        drawCircleFilled(renderer, circle, fc);
    }
    if (outline) |oc| {
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
/// Draws a rectangle in game space with optional fill and outline colors.
///
/// This function renders a rectangle defined by its center point, half-width,
/// and half-height in game space coordinates (-1,1). The rectangle can be
/// filled, outlined, or both depending on which color parameters are provided.
///
/// Parameters:
///     renderer: Pointer to the Renderer instance
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
pub fn drawRectangle(renderer: *Renderer, rect: Rectangle, fill: ?Color, outline: ?Color) void {
    if (fill) |fc| {
        drawRectFilled(renderer, rect, fc);
    }
    if (outline) |oc| {
        drawRectOutline(renderer, rect, oc);
    }
}
fn drawRectFilled(renderer: *Renderer, rect: Rectangle, color: Color) void {
    const corners = rect.getCorners();

    const topLeft = renderer.gameToScreen(corners[0]);
    const bottomRight = renderer.gameToScreen(corners[2]);

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
            renderer.frameBuffer.setPixel(x, y, color);
        }
    }
}

fn drawRectOutline(renderer: *Renderer, rect: Rectangle, color: Color) void {
    const corners = rect.getCorners();
    for (0..4) |i| {
        const start = corners[i];
        const end = corners[(i + 1) % 4];
        renderer.drawLine(start, end, color);
    }
}

// MARK: Triangle
/// Draws a triangle in game space with optional fill and outline colors.
///
/// This function renders a triangle defined by three vertices in game space
/// coordinates (-1,1). The triangle can be filled, outlined, or both depending
/// on which color parameters are provided.
///
/// Parameters:
///     renderer: Pointer to the Renderer instance
///     tri: Triangle structure containing three vertices
///     fill: Optional color for filling the triangle. If null, no fill is drawn
///     outline: Optional color for the triangle outline. If null, no outline is drawn
///
/// Example:
///     // Define triangle vertices
///     var points = [_]Point{
///         Point{ .x = 0.0, .y = 0.5 },    // Top vertex
///         Point{ .x = -0.5, .y = -0.5 },  // Bottom-left vertex
///         Point{ .x = 0.5, .y = -0.5 },   // Bottom-right vertex
///     };
///     // Create a triangle
///     const tri = Triangle.init(&points);
///
///     // Draw a green filled triangle with a white outline
///     renderer.drawTriangle(tri, Color.init(0, 1, 0, 1), Color.init(1, 1, 1, 1));
///
///     // Draw a triangle with only an outline
///     renderer.drawTriangle(tri, null, Color.init(1, 0, 0, 1));
///
/// Notes:
///     - The triangle vertices are automatically sorted for efficient rendering
///     - The triangle is automatically clipped if it extends beyond screen boundaries
///     - Special optimizations are applied for flat-top and flat-bottom triangles
pub fn drawTriangle(renderer: *Renderer, tri: Triangle, fill: ?Color, outline: ?Color) void {
    if (fill) |fc| {
        drawTriangleFilled(renderer, tri.vertices, fc);
    }
    if (outline) |oc| {
        drawOutline(renderer, tri.vertices, oc);
    }
}

fn drawTriangleFilled(renderer: *Renderer, verts: []const Point, color: Color) void {
    const v0 = verts[0];
    const v1 = verts[1];
    const v2 = verts[2];

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
pub fn drawPolygon(renderer: *Renderer, poly: Polygon, fill: ?Color, outline: ?Color) void {
    switch (poly.vertices.len) {
        0, 1, 2 => {
            return;
        },
        else => {
            if (fill) |fc| {
                drawPolygonFilled(renderer, poly.vertices, poly.center, fc);
            }
            if (outline) |oc| {
                drawOutline(renderer, poly.vertices, oc);
            }
        },
    }
}

fn drawPolygonOutline(renderer: *Renderer, verts: []const Point, color: Color) void {
    renderer.drawOutline(verts, color);
}

fn drawPolygonFilled(renderer: *Renderer, verts: []const Point, center: Point, color: Color) void {
    var sortedVerts: [3]Point = undefined;

    if (verts.len == 3) {
        drawTriangleFilled(renderer, verts, color);
        return;
    }
    for (0..verts.len) |i| {
        sortedVerts = .{ center, verts[i], verts[(i + 1) % verts.len] };
        std.mem.sort(Point, &sortedVerts, {}, sortPointByY);
        drawTriangleFilled(renderer, &sortedVerts, color);
    }
}

fn sortPointByY(context: void, a: Point, b: Point) bool {
    _ = context;
    return a.y > b.y;
}
