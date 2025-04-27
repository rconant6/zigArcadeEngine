const std = @import("std");
const bge = @import("bridge.zig");
const gsm = @import("gameStateManager.zig");
const gss = @import("gameStates.zig");

const KeyCodes = bge.GameKeyCode;

const TARGET_FPS: f32 = 60.0;
const TARGET_FRAME_TIME_NS: i64 = @intFromFloat((1.0 / TARGET_FPS) * std.time.ns_per_s);
const F32_NS_PER_S: f32 = @floatFromInt(std.time.ns_per_s);

pub fn main() !void {
    // MARK: External stuff that feeds the game
    // Initialize the application
    const app = bge.c.wb_initApplication();
    if (app == 0) {
        std.debug.print("Failed to initialize application\n", .{});
        return error.ApplicationInitFailed;
    }
    // Create a window
    var window = try bge.Window.create(.{
        .width = 800,
        .height = 600,
        .title = "ZASTEROIDS",
    });
    defer window.destroy();
    // Initialize keyboard
    var keyboard = try bge.Keyboard.init();
    defer keyboard.deinit();

    // MARK: Internal stuff that runs the game
    var stateManager = gsm.GameStateManager.init(); // place holder for the engine

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

        frameEndTime = std.time.microTimestamp();
        frameDuration = frameEndTime - currentTime;

        sleepTime = TARGET_FRAME_TIME_NS - frameDuration;
        if (sleepTime > 0) {
            std.Thread.sleep(@intCast(sleepTime));
        } else {
            std.debug.print("Missed frametime by: {d}", .{sleepTime});
        }
    }

    std.debug.print("Application shutting down\n", .{});
}
