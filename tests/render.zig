test {
    _ = @import("render.zig");
}

const std = @import("std");
const testing = std.testing;

const testUtils = @import("utils.zig");

// Import your renderer types
const rend = @import("renderer");
const Renderer = rend.Renderer;
const Color = rend.Color;
const Point = rend.Point;
const ScreenPoint = rend.ScreenPoint;
const Rectangle = rend.Rectangle;
const Circle = rend.Circle;
const Triangle = rend.Triangle;
const Polygon = rend.Polygon;

test "renderer initialization and cleanup" {
    var allocator = testUtils.createTestAllocator();

    var renderer = try Renderer.init(&allocator, testUtils.TestConfig.RENDER_TEST_WIDTH, testUtils.TestConfig.RENDER_TEST_HEIGHT);
    defer renderer.deinit();

    try testing.expect(renderer.width == testUtils.TestConfig.RENDER_TEST_WIDTH);
    try testing.expect(renderer.height == testUtils.TestConfig.RENDER_TEST_HEIGHT);
    try testing.expect(renderer.fw == @as(f32, @floatFromInt(testUtils.TestConfig.RENDER_TEST_WIDTH)));
    try testing.expect(renderer.fh == @as(f32, @floatFromInt(testUtils.TestConfig.RENDER_TEST_HEIGHT)));
}

test "coordinate transformation game to screen" {
    var allocator = testUtils.createTestAllocator();
    var renderer = try Renderer.init(&allocator, 800, 600);
    defer renderer.deinit();

    // Test center point (0,0) -> (400, 300)
    const center_game = Point.init(0.0, 0.0);
    const center_screen = renderer.gameToScreen(center_game);
    try testing.expect(center_screen.x == 400);
    try testing.expect(center_screen.y == 300);

    // Test top-left (-1,1) -> (0, 0)
    const top_left_game = Point.init(-1.0, 1.0);
    const top_left_screen = renderer.gameToScreen(top_left_game);
    try testing.expect(top_left_screen.x == 0);
    try testing.expect(top_left_screen.y == 0);

    // Test bottom-right (1,-1) -> (800, 600)
    const bottom_right_game = Point.init(1.0, -1.0);
    const bottom_right_screen = renderer.gameToScreen(bottom_right_game);
    try testing.expect(bottom_right_screen.x == 800);
    try testing.expect(bottom_right_screen.y == 600);
}

test "coordinate transformation screen to game" {
    var allocator = testUtils.createTestAllocator();
    var renderer = try Renderer.init(&allocator, 800, 600);
    defer renderer.deinit();

    // Test center point (400, 300) -> (0,0)
    const center_screen = ScreenPoint.init(400, 300);
    const center_game = renderer.screenToGame(center_screen);
    try testing.expect(@abs(center_game.x - 0.0) < 0.001);
    try testing.expect(@abs(center_game.y - 0.0) < 0.001);

    // Test top-left (0, 0) -> (-1,1)
    const top_left_screen = ScreenPoint.init(0, 0);
    const top_left_game = renderer.screenToGame(top_left_screen);
    try testing.expect(@abs(top_left_game.x - (-1.0)) < 0.001);
    try testing.expect(@abs(top_left_game.y - 1.0) < 0.001);

    // Test bottom-right (800, 600) -> (1,-1)
    const bottom_right_screen = ScreenPoint.init(800, 600);
    const bottom_right_game = renderer.screenToGame(bottom_right_screen);
    try testing.expect(@abs(bottom_right_game.x - 1.0) < 0.001);
    try testing.expect(@abs(bottom_right_game.y - (-1.0)) < 0.001);
}

test "frame buffer begins and ends correctly" {
    var allocator = testUtils.createTestAllocator();
    var renderer = try Renderer.init(&allocator, 100, 100);
    defer renderer.deinit();

    // Test that we can call begin/end frame without errors
    renderer.beginFrame();
    renderer.endFrame();

    // Frame buffer should be accessible
    const buffer = renderer.getRawFrameBuffer();
    try testing.expect(buffer.len == 100 * 100);
}

test "clear color setting and frame clearing" {
    var allocator = testUtils.createTestAllocator();
    var renderer = try Renderer.init(&allocator, 10, 10);
    defer renderer.deinit();

    // Set clear color to red
    const red = Color.init(1.0, 0.0, 0.0, 1.0);
    renderer.setClearColor(red);

    // Begin frame should clear with the set color
    renderer.beginFrame();

    // Check that clear color was applied (this is implementation-dependent)
    try testing.expect(renderer.clearColor.r == 1.0);
    try testing.expect(renderer.clearColor.g == 0.0);
    try testing.expect(renderer.clearColor.b == 0.0);
    try testing.expect(renderer.clearColor.a == 1.0);
}

test "point drawing within bounds" {
    var allocator = testUtils.createTestAllocator();
    var renderer = try Renderer.init(&allocator, 100, 100);
    defer renderer.deinit();

    renderer.beginFrame();

    // Draw point at center
    const center_point = Point.init(0.0, 0.0);
    const white = Color.init(1.0, 1.0, 1.0, 1.0);
    renderer.drawPoint(center_point, white);

    // Draw point at edges (should not crash)
    renderer.drawPoint(Point.init(-1.0, 1.0), white);
    renderer.drawPoint(Point.init(1.0, -1.0), white);

    renderer.endFrame();
}

test "line drawing basic functionality" {
    var allocator = testUtils.createTestAllocator();
    var renderer = try Renderer.init(&allocator, 100, 100);
    defer renderer.deinit();

    renderer.beginFrame();

    const white = Color.init(1.0, 1.0, 1.0, 1.0);

    // Horizontal line
    renderer.drawLine(Point.init(-0.5, 0.0), Point.init(0.5, 0.0), white);

    // Vertical line
    renderer.drawLine(Point.init(0.0, -0.5), Point.init(0.0, 0.5), white);

    // Diagonal line
    renderer.drawLine(Point.init(-0.5, -0.5), Point.init(0.5, 0.5), white);

    renderer.endFrame();
}

test "rectangle creation and properties" {
    // Test rectangle creation methods
    const center = Point.init(0.0, 0.0);
    const rect_from_center = Rectangle.initFromCenter(center, 2.0, 1.0);

    try testing.expect(rect_from_center.center.x == 0.0);
    try testing.expect(rect_from_center.center.y == 0.0);
    try testing.expect(rect_from_center.halfWidth == 1.0);
    try testing.expect(rect_from_center.halfHeight == 0.5);
    try testing.expect(rect_from_center.getWidth() == 2.0);
    try testing.expect(rect_from_center.getHeight() == 1.0);

    // Test square creation
    const square = Rectangle.initSquare(center, 2.0);
    try testing.expect(square.halfWidth == 1.0);
    try testing.expect(square.halfHeight == 1.0);
    try testing.expect(square.getWidth() == 2.0);
    try testing.expect(square.getHeight() == 2.0);
}

test "rectangle corner calculation" {
    const center = Point.init(0.5, -0.25);
    const rect = Rectangle.initFromCenter(center, 1.0, 0.5);
    const corners = rect.getCorners();

    // Should return [topLeft, topRight, bottomRight, bottomLeft]
    try testing.expect(corners[0].x == 0.0); // topLeft.x
    try testing.expect(corners[0].y == 0.0); // topLeft.y
    try testing.expect(corners[1].x == 1.0); // topRight.x
    try testing.expect(corners[1].y == 0.0); // topRight.y
    try testing.expect(corners[2].x == 1.0); // bottomRight.x
    try testing.expect(corners[2].y == -0.5); // bottomRight.y
    try testing.expect(corners[3].x == 0.0); // bottomLeft.x
    try testing.expect(corners[3].y == -0.5); // bottomLeft.y
}

test "rectangle drawing" {
    var allocator = testUtils.createTestAllocator();
    var renderer = try Renderer.init(&allocator, 200, 200);
    defer renderer.deinit();

    renderer.beginFrame();

    const rect = Rectangle.initFromCenter(Point.init(0.0, 0.0), 1.0, 0.8);
    const fill_color = Color.init(0.5, 0.5, 1.0, 1.0);
    const outline_color = Color.init(1.0, 1.0, 1.0, 1.0);

    // Should not crash
    renderer.drawRectangle(rect, fill_color, outline_color);
    renderer.drawRectangle(rect, fill_color, null); // Fill only
    renderer.drawRectangle(rect, null, outline_color); // Outline only

    renderer.endFrame();
}

test "circle drawing" {
    var allocator = testUtils.createTestAllocator();
    var renderer = try Renderer.init(&allocator, 200, 200);
    defer renderer.deinit();

    renderer.beginFrame();

    const circle = Circle{ .origin = Point.init(0.0, 0.0), .radius = 0.5 };
    const fill_color = Color.init(1.0, 0.0, 0.0, 1.0);
    const outline_color = Color.init(0.0, 1.0, 0.0, 1.0);

    // Should not crash
    renderer.drawCircle(circle, fill_color, outline_color);
    renderer.drawCircle(circle, fill_color, null); // Fill only
    renderer.drawCircle(circle, null, outline_color); // Outline only

    renderer.endFrame();
}

test "triangle creation and drawing" {
    var allocator = testUtils.createTestAllocator();
    var renderer = try Renderer.init(&allocator, 200, 200);
    defer renderer.deinit();

    renderer.beginFrame();

    // Create triangle points
    var points = [_]Point{
        Point.init(0.0, 0.5), // Top
        Point.init(-0.5, -0.5), // Bottom-left
        Point.init(0.5, -0.5), // Bottom-right
    };
    const triangle = Triangle.init(&points);

    const fill_color = Color.init(0.0, 1.0, 0.0, 1.0);
    const outline_color = Color.init(1.0, 1.0, 1.0, 1.0);

    // Should not crash
    renderer.drawTriangle(triangle, fill_color, outline_color);
    renderer.drawTriangle(triangle, fill_color, null); // Fill only
    renderer.drawTriangle(triangle, null, outline_color); // Outline only

    renderer.endFrame();
}

test "polygon creation and drawing" {
    var allocator = testUtils.createTestAllocator();
    var renderer = try Renderer.init(&allocator, 200, 200);
    defer renderer.deinit();

    renderer.beginFrame();

    // Create pentagon
    var points = [_]Point{
        Point.init(0.0, 0.5), // Top
        Point.init(0.4, 0.2), // Top-right
        Point.init(0.3, -0.3), // Bottom-right
        Point.init(-0.3, -0.3), // Bottom-left
        Point.init(-0.4, 0.2), // Top-left
    };
    const polygon = Polygon.init(&points);

    const fill_color = Color.init(1.0, 0.5, 0.0, 1.0);
    const outline_color = Color.init(0.0, 0.0, 1.0, 1.0);

    // Should not crash
    renderer.drawPolygon(polygon, fill_color, outline_color);
    renderer.drawPolygon(polygon, fill_color, null); // Fill only
    renderer.drawPolygon(polygon, null, outline_color); // Outline only

    renderer.endFrame();
}

test "color creation and properties" {
    // Test normalized float constructor
    const red = Color.init(1.0, 0.0, 0.0, 1.0);
    try testing.expect(red.r == 1.0);
    try testing.expect(red.g == 0.0);
    try testing.expect(red.b == 0.0);
    try testing.expect(red.a == 1.0);

    // Test byte constructor
    const blue = Color.initFromInt(0, 0, 255, 128);
    try testing.expect(blue.r == 0.0);
    try testing.expect(blue.g == 0.0);
    try testing.expect(@abs(blue.b - 1.0) < 0.001);
    try testing.expect(@abs(blue.a - 0.502) < 0.01); // 128/255 ≈ 0.502
}

test "screen point utilities" {
    const p1 = ScreenPoint.init(100, 200);
    const p2 = ScreenPoint.init(100, 200);
    const p3 = ScreenPoint.init(150, 200);

    try testing.expect(p1.isSamePoint(p2));
    try testing.expect(!p1.isSamePoint(p3));
}

test "drawing with null colors does not crash" {
    var allocator = testUtils.createTestAllocator();
    var renderer = try Renderer.init(&allocator, 100, 100);
    defer renderer.deinit();

    renderer.beginFrame();

    // All of these should be no-ops and not crash
    renderer.drawPoint(Point.init(0.0, 0.0), null);
    renderer.drawLine(Point.init(-0.5, 0.0), Point.init(0.5, 0.0), null);

    const rect = Rectangle.initSquare(Point.init(0.0, 0.0), 0.5);
    renderer.drawRectangle(rect, null, null);

    const circle = Circle{ .origin = Point.init(0.0, 0.0), .radius = 0.3 };
    renderer.drawCircle(circle, null, null);

    renderer.endFrame();
}

test "outline drawing with various point counts" {
    var allocator = testUtils.createTestAllocator();
    var renderer = try Renderer.init(&allocator, 100, 100);
    defer renderer.deinit();

    renderer.beginFrame();

    const white = Color.init(1.0, 1.0, 1.0, 1.0);

    // Single point
    var single_point = [_]Point{Point.init(0.0, 0.0)};
    renderer.drawOutline(&single_point, white);

    // Two points (line)
    var two_points = [_]Point{
        Point.init(-0.2, 0.0),
        Point.init(0.2, 0.0),
    };
    renderer.drawOutline(&two_points, white);

    // Triangle outline
    var triangle_points = [_]Point{
        Point.init(0.0, 0.3),
        Point.init(-0.3, -0.3),
        Point.init(0.3, -0.3),
    };
    renderer.drawOutline(&triangle_points, white);

    // Empty array should not crash
    var empty_points = [_]Point{};
    renderer.drawOutline(&empty_points, white);

    renderer.endFrame();
}

test "renderer handles edge coordinate values" {
    var allocator = testUtils.createTestAllocator();
    var renderer = try Renderer.init(&allocator, 100, 100);
    defer renderer.deinit();

    renderer.beginFrame();

    const white = Color.init(1.0, 1.0, 1.0, 1.0);

    // Points at exact boundaries
    renderer.drawPoint(Point.init(-1.0, 1.0), white); // Top-left
    renderer.drawPoint(Point.init(1.0, 1.0), white); // Top-right
    renderer.drawPoint(Point.init(-1.0, -1.0), white); // Bottom-left
    renderer.drawPoint(Point.init(1.0, -1.0), white); // Bottom-right

    // Points outside boundaries (should be clipped gracefully)
    renderer.drawPoint(Point.init(-2.0, 2.0), white);
    renderer.drawPoint(Point.init(2.0, -2.0), white);

    // Lines crossing boundaries
    renderer.drawLine(Point.init(-2.0, 0.0), Point.init(2.0, 0.0), white);
    renderer.drawLine(Point.init(0.0, -2.0), Point.init(0.0, 2.0), white);

    renderer.endFrame();
}
