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
        drawTestRects(&renderer);
        drawTestLines(&renderer);
        drawTestTriangles(&renderer);

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

fn drawTestLines(renderer: *Renderer) void {
    const radius = 0.56;
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
    // Flat Bottom
    const v11: Point = .{ .x = -0.3, .y = -1 };
    const v22: Point = .{ .x = 0.3, .y = -1 };
    const v33: Point = .{ .x = 0, .y = 0 };
    // Non-Flat Triangle
    const r1: Point = .{ .x = -0.65, .y = -0.8 };
    const r2: Point = .{ .x = -0.95, .y = 0 };
    const r3: Point = .{ .x = 0.1, .y = -0.35 };

    renderer.drawTriangle(
        .{ .vertices = .{ v1, v2, v3 } },
        Color.init(0.2, 0.5, 0.8, 1),
        Color.init(0.2, 0.8, 0.5, 1),
    );
    renderer.drawTriangle(
        .{ .vertices = .{ v11, v22, v33 } },
        Color.init(0.2, 0.5, 0.8, 1),
        Color.init(0.2, 0.8, 0.5, 1),
    );
    renderer.drawTriangle(
        .{ .vertices = .{ r1, r2, r3 } },
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
