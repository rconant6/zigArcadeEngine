const std = @import("std");
const bge = @import("bridge.zig");
const gsm = @import("gameStateManager.zig");
const gss = @import("gameStates.zig");

const KeyCodes = bge.GameKeyCode;
const Renderer = @import("renderer.zig").Renderer;
const Color = @import("renderer.zig").Color;
const Point = @import("primitives.zig").Point;
const Line = @import("primitives.zig").Line;

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
        std.debug.print("Failed to initialize application\n", .{});
        return error.ApplicationInitFailed;
    }
    // Create a window
    var window = try bge.Window.create(.{
        .width = WIDTH,
        .height = HEIGHT,
        .title = "ZASTEROIDS",
    });
    defer window.destroy();
    // Initialize keyboard
    var keyboard = try bge.Keyboard.init();
    defer keyboard.deinit();

    // MARK: Internal stuff that runs the game
    var stateManager = gsm.GameStateManager.init(); // place holder for the engine
    var renderer = Renderer.init(&allocator, WIDTH, HEIGHT);
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
        // Process window events
        window.processEvents();

        stateManager.update(dt);

        // Check window close
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
        // do a test of draw point in the center of the screen
        renderer.drawPoint(.{ .x = 0, .y = 0 }, Color.init(1, 1, 1, 1));
        // show the corners colored in to ensure mapping is correct
        drawTestCorners(&renderer);

        drawTestLines(&renderer);

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
    // random point for same testing
    // const random: Point = .{ .x = 0.0, .y = 0.0 };
    // const random2: Point = .{ .x = 0.5, .y = -0.666 };
    const diagStart: Point = .{ .x = -0.375, .y = 0.667 };
    const diagEnd: Point = .{ .x = 0.375, .y = -0.666 };
    const diagStart2: Point = .{ .x = -0.375, .y = -0.667 };
    const diagEnd2: Point = .{ .x = 0.375, .y = 0.666 };
    const diagLine: Line = .{ .start = diagStart, .end = diagEnd };
    const diagLine2: Line = .{ .start = diagStart2, .end = diagEnd2 };
    // renderer.drawLinePts(diagStart, diagEnd, Color.init(0, 0, 0, 1));
    renderer.drawLine(diagLine, Color.init(0, 0, 0, 1));
    // renderer.drawLinePts(diagStart2, diagEnd2, Color.init(0, 0, 0, 1));
    renderer.drawLine(diagLine2, Color.init(1, 1, 1, 1));
    renderer.drawLinePts(leftEdge, rightEdge, Color.init(0, 1, 1, 1));
    renderer.drawLinePts(topEdge, bottomEdge, Color.init(0, 1, 1, 1));
    renderer.drawLinePts(center, topLeft, Color.init(1, 0, 0, 1));
    renderer.drawLinePts(center, topRight, Color.init(0, 1, 0, 1));
    renderer.drawLinePts(center, botLeft, Color.init(0, 0, 1, 1));
    renderer.drawLinePts(center, botRight, Color.init(1, 1, 0, 1));
}

fn drawTestCorners(renderer: *Renderer) void {
    // Make 10x10 pixel squares in each corner for easier visibility
    // Top-left: Red
    for (0..10) |y| {
        for (0..10) |x| {
            renderer.frameBuffer.setPixel(
                @intCast(x),
                @intCast(y),
                Color.init(1.0, 0.0, 0.0, 1.0),
            );
        }
    }

    // Top-right: Green
    for (0..10) |y| {
        for (0..10) |x| {
            renderer.frameBuffer.setPixel(
                @intCast(WIDTH - 1 - x),
                @intCast(y),
                Color.init(0.0, 1.0, 0.0, 1.0),
            );
        }
    }

    // Bottom-left: Blue
    for (0..10) |y| {
        for (0..10) |x| {
            renderer.frameBuffer.setPixel(
                @intCast(x),
                @intCast(HEIGHT - 1 - y),
                Color.init(0.0, 0.0, 1.0, 1.0),
            );
        }
    }

    // Bottom-right: Yellow
    for (0..10) |y| {
        for (0..10) |x| {
            renderer.frameBuffer.setPixel(
                @intCast(WIDTH - 1 - x),
                @intCast(HEIGHT - 1 - y),
                Color.init(1.0, 1.0, 0.0, 1.0),
            );
        }
    }
}
