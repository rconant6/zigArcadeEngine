const std = @import("std");
const bge = @import("bridge.zig");
const gsm = @import("gameStateManager.zig");
const gss = @import("gameStates.zig");
const prim = @import("primitives.zig");

const KeyCodes = bge.GameKeyCode;
const Renderer = @import("renderer.zig").Renderer;

const Circle = prim.Circle;
const Color = prim.Color;
const Line = prim.Line;
const Point = prim.Point;
const Rectangle = prim.Rectangle;
const Triangle = prim.Triangle;
const Polygon = prim.Polygon;

const TARGET_FPS: f32 = 60.0;
const TARGET_FRAME_TIME_NS: i64 = @intFromFloat((1.0 / TARGET_FPS) * std.time.ns_per_s);
const F32_NS_PER_S: f32 = @floatFromInt(std.time.ns_per_s);
const WIDTH: i32 = 1600;
const HEIGHT: i32 = 900;
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocator = gpa.allocator();

    // MARK: External stuff that feeds the game
    // Initialize the application
    const app = bge.c.wb_initApplication();
    if (app == 0) {
        std.process.fatal("[MAIN] failed to initialize native application: {}\n", .{error.FailedApplicationLaunch});
    }
    // Create a window
    var window = try bge.Window.create(.{
        .width = WIDTH,
        .height = HEIGHT,
        .title = "ZASTEROIDS",
    });
    defer window.destroy();
    // Initialize keyboard
    var keyboard = bge.Keyboard.init() catch |err| {
        std.process.fatal("[MAIN] failed to initialize keyboard input: {}\n", .{err});
    };
    defer keyboard.deinit();

    // MARK: Internal stuff that runs the game
    var stateManager = gsm.GameStateManager.init(); // place holder for the engine
    var renderer = Renderer.init(&allocator, WIDTH, HEIGHT) catch |err| {
        std.process.fatal("[MAIN] failed to initialize renderer: {}\n", .{err});
    };
    defer renderer.deinit();
    // Main loop
    var running = true;
    var currentTime: i64 = std.time.microTimestamp();
    var frameEndTime: i64 = currentTime;
    var frameDuration: i64 = 0;
    var sleepTime: i64 = 0;
    var elapsed: f32 = 0.0;
    var dt: f32 = 0.0;

    while (running) {
        currentTime = std.time.microTimestamp();
        elapsed = @floatFromInt(currentTime - frameEndTime);
        dt = elapsed / F32_NS_PER_S;
        window.processEvents();

        stateManager.update(dt);

        if (window.shouldClose()) {
            running = false;
            continue;
        }

        // Check for keyboard input
        while (keyboard.pollEvent()) |keyEvent| {
            std.debug.print(
                "[MAIN] - Key event: code={}, pressed={}\n",
                .{ keyEvent.keyCode, keyEvent.isPressed },
            );

            stateManager.processKeyEvent(keyEvent);

            if (keyEvent.keyCode == .Esc) {
                running = false;
            }
        }

        renderer.beginFrame();

        // Test shape drawing on the renderer
        // drawTestRects(&renderer);
        drawTestLines(&renderer);
        // drawTestTriangles(&renderer);
        drawTestPolygons(&renderer);

        renderer.endFrame();

        window.updateWindowPixels(
            renderer.getRawFrameBuffer(),
            WIDTH,
            HEIGHT,
        );

        frameEndTime = std.time.microTimestamp();
        frameDuration = frameEndTime - currentTime;

        sleepTime = TARGET_FRAME_TIME_NS - frameDuration;
        if (sleepTime > 0) {
            // std.debug.print("sleeptime by: {d}\n", .{sleepTime});
            std.Thread.sleep(@intCast(sleepTime));
        } else {
            std.debug.print("Missed frametime by: {d}", .{sleepTime});
        }
    }

    std.debug.print("Application shutting down\n", .{});
}

fn drawTestPolygons(renderer: *Renderer) void {
    // 3 sided
    const t1: Point = .{ .x = -0.85, .y = 0.95 };
    const t2: Point = .{ .x = -0.95, .y = 0.75 };
    const t3: Point = .{ .x = -0.65, .y = 0.85 };
    var points = [_]Point{ t1, t2, t3 };
    const triPoly = Polygon.init(&points);
    renderer.drawPolygon(triPoly, null, Color.init(0.2, 0.3, 0.9, 1));

    // 4 sided
    const f1: Point = .{ .x = 0.45, .y = 0.95 };
    const f2: Point = .{ .x = 0.55, .y = 0.95 };
    const f3: Point = .{ .x = 0.75, .y = 0.1 };
    const f4: Point = .{ .x = 0.25, .y = 0.1 };
    var points2 = [_]Point{ f2, f1, f3, f4 };
    const quadPoly = Polygon.init(&points2);
    renderer.drawPolygon(quadPoly, null, Color.init(0.5, 0.9, 0.7, 1));

    // 5 sided
    const p1: Point = .{ .x = -0.7, .y = -0.5 }; // top point
    const p2: Point = .{ .x = -0.85, .y = -0.65 };
    const p3: Point = .{ .x = -0.75, .y = -0.85 };
    const p4: Point = .{ .x = -0.55, .y = -0.85 };
    const p5: Point = .{ .x = -0.45, .y = -0.65 };
    var points3 = [_]Point{ p1, p2, p3, p4, p5 };
    const pentaPoly = Polygon.init(&points3);
    renderer.drawPolygon(pentaPoly, Color.init(0.6, 0.2, 0.8, 1), Color.init(0.8, 0.4, 0.9, 1));

    // 10 sided
    const d1: Point = .{ .x = 0.75, .y = -0.5 }; // top point
    const d2: Point = .{ .x = 0.64, .y = -0.59 };
    const d3: Point = .{ .x = 0.57, .y = -0.71 };
    const d4: Point = .{ .x = 0.57, .y = -0.83 };
    const d5: Point = .{ .x = 0.65, .y = -0.91 };
    const d6: Point = .{ .x = 0.75, .y = -0.94 };
    const d7: Point = .{ .x = 0.85, .y = -0.91 };
    const d8: Point = .{ .x = 0.93, .y = -0.83 };
    const d9: Point = .{ .x = 0.93, .y = -0.71 };
    const d10: Point = .{ .x = 0.86, .y = -0.59 };
    var points4 = [_]Point{ d1, d2, d3, d4, d5, d6, d7, d8, d9, d10 };
    const decaPoly = Polygon.init(&points4);
    renderer.drawPolygon(decaPoly, Color.init(0.3, 0.7, 0.4, 1), Color.init(0.1, 0.5, 0.2, 1));

    // 12
    const x1: Point = .{ .x = 0.1, .y = 0.3 };
    const x2: Point = .{ .x = 0.25, .y = 0.15 };
    const x3: Point = .{ .x = 0.32, .y = -0.05 };
    const x4: Point = .{ .x = 0.28, .y = -0.22 };
    const x5: Point = .{ .x = 0.18, .y = -0.35 };
    const x6: Point = .{ .x = 0.02, .y = -0.38 };
    const x7: Point = .{ .x = -0.15, .y = -0.33 };
    const x8: Point = .{ .x = -0.27, .y = -0.25 };
    const x9: Point = .{ .x = -0.35, .y = -0.1 };
    const x10: Point = .{ .x = -0.3, .y = 0.08 };
    const x11: Point = .{ .x = -0.2, .y = 0.2 };
    const x12: Point = .{ .x = -0.05, .y = 0.28 };
    var points5 = [_]Point{ x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12 };
    const irregPoly = Polygon.init(&points5);
    renderer.drawPolygon(irregPoly, Color.init(0.8, 0.6, 0.1, 1), Color.init(1.0, 0.8, 0.2, 1));
}

fn drawTestCircles(renderer: *Renderer) void {
    const radius = 0.56;
    const center: Point = .{ .x = 0, .y = 0 }; // Center of screen
    const centerCircle: Circle = .{ .origin = center, .radius = radius };
    renderer.drawCircle(centerCircle, Color.init(1, 0.5, 0.8, 1), Color.init(0.75, 0.75, 0.75, 1));
    const radius2 = 0.15;
    renderer.drawCircle(
        .{ .origin = .{ .x = -0.25, .y = -0.25 }, .radius = radius2 },
        null,
        Color.init(0.85, 0, 1, 1),
    );
    renderer.drawCircle(
        .{ .origin = .{ .x = 0.50, .y = 0.50 }, .radius = radius2 },
        Color.init(0.85, 0.5, 1, 1),
        null,
    );
}
fn drawTestLines(renderer: *Renderer) void {
    const center: Point = .{ .x = 0, .y = 0 }; // Center of screen
    const topLeft: Point = .{ .x = -1, .y = 1 }; // Top-left corner
    const topRight: Point = .{ .x = 1, .y = 1 }; // Top-right corner
    const botLeft: Point = .{ .x = -1, .y = -1 }; // Bottom-left corner
    const botRight: Point = .{ .x = 1, .y = -1 }; // Bottom-right corner
    // horizontal line
    const leftEdge: Point = .{ .x = -1, .y = 0 };
    const rightEdge: Point = .{ .x = 1, .y = 0 };
    // vertical line
    const topEdge: Point = .{ .x = 0, .y = 1 };
    const bottomEdge: Point = .{ .x = 0, .y = -1 };
    // diagonal lines
    const diagStart: Point = .{ .x = -0.375, .y = 0.667 };
    const diagEnd: Point = .{ .x = 0.375, .y = -0.666 };
    const diagStart2: Point = .{ .x = -0.375, .y = -0.667 };
    const diagEnd2: Point = .{ .x = 0.375, .y = 0.666 };
    // const diagLine: Line = .{ .start = diagEnd, .end = diagStart };
    // const diagLine2: Line = .{ .start = diagStart2, .end = diagEnd2 };
    renderer.drawLine(diagStart, diagEnd, Color.init(0, 0, 0, 1));
    // renderer.drawLine(diagLine, Color.init(0.25, 0.25, 0.25, 1));
    renderer.drawLine(diagStart2, diagEnd2, Color.init(0, 0, 0, 1));
    // renderer.drawLine(diagLine2, Color.init(0.3, 0.3, 0.3, 1));
    renderer.drawLine(leftEdge, rightEdge, Color.init(0, 1, 1, 1));
    renderer.drawLine(topEdge, bottomEdge, Color.init(0, 1, 1, 1));
    renderer.drawLine(topLeft, center, Color.init(1, 0, 0, 1));
    renderer.drawLine(center, topRight, Color.init(0, 1, 0, 1));
    renderer.drawLine(botLeft, center, Color.init(0, 0, 1, 1));
    renderer.drawLine(center, botRight, Color.init(1, 1, 0, 1));
}

fn drawTestTriangles(renderer: *Renderer) void {
    // Flat Top
    const v1: Point = .{ .x = 0.5, .y = 1 };
    const v2: Point = .{ .x = -0.5, .y = 1 };
    const v3: Point = .{ .x = 0, .y = 0 };
    var points = [_]Point{ v1, v2, v3 };
    const t1 = Triangle.init(&points);
    // Flat Bottom
    const v11: Point = .{ .x = -0.3, .y = -1 };
    const v22: Point = .{ .x = 0.3, .y = -1 };
    const v33: Point = .{ .x = 0, .y = 0 };
    var points2 = [_]Point{ v11, v22, v33 };
    const t2 = Triangle.init(&points2);
    // Non-Flat Triangle
    const r1: Point = .{ .x = -0.65, .y = -0.8 };
    const r2: Point = .{ .x = -0.95, .y = 0 };
    const r3: Point = .{ .x = 0.1, .y = -0.35 };
    var points3 = [_]Point{ r1, r2, r3 };
    const t3 = Triangle.init(&points3);

    renderer.drawTriangle(
        t1,
        Color.init(0.2, 0.5, 0.8, 1),
        Color.init(0.2, 0.8, 0.5, 1),
    );
    renderer.drawTriangle(
        t2,
        Color.init(0.2, 0.5, 0.8, 1),
        Color.init(0.2, 0.8, 0.5, 1),
    );
    renderer.drawTriangle(
        t3,
        Color.init(0.2, 0.5, 0.8, 1),
        Color.init(0.2, 0.8, 0.5, 1),
    );
}

fn drawTestRects(renderer: *Renderer) void {
    const rect = Rectangle.initFromCenter(.{ .x = 0, .y = 0 }, 1.8, 1.8);
    const square = Rectangle.initSquare(.{ .x = 0, .y = 0 }, 1.5);
    renderer.drawRectangle(rect, Color.init(1, 1, 1, 1), Color.init(1, 1, 1, 1));
    renderer.drawRectangle(square, Color.init(0, 1, 1, 1), Color.init(0, 1, 1, 1));
}
