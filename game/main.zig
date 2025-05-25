const std = @import("std");

const bge = @import("bridge.zig");
const KeyCodes = bge.GameKeyCode;

const gsm = @import("gameStateManager.zig");
const GameStateManager = gsm.GameStateManager;

const ecs = @import("ecs.zig");
const ComponentType = ecs.ComponentType;
const Entity = ecs.Entity;
const EntityManager = ecs.EntityManager;
// const TransformComp = ecs.TransformComp;

const rend = @import("renderer.zig");
const Circle = rend.Circle;
const Color = rend.Color;
const Line = rend.Line;
const Point = rend.Point;
const Rectangle = rend.Rectangle;
const Renderer = rend.Renderer;
const ScreenPoint = rend.ScreenPoint;
const Triangle = rend.Triangle;
const Polygon = rend.Polygon;

const Config = struct {
    const TARGET_FPS: f32 = 60.0;
    const TARGET_FRAME_TIME_NS: i64 = @intFromFloat((1.0 / TARGET_FPS) * std.time.ns_per_s);
    const F32_NS_PER_S: f32 = @floatFromInt(std.time.ns_per_s);
    const WIDTH: i32 = 1600;
    const HEIGHT: i32 = 900;
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocator = gpa.allocator();

    // MARK: External stuff that feeds the game
    // Initialize the application
    const app = bge.c.wb_initApplication();
    if (app == 0) {
        std.process.fatal(
            "[MAIN] failed to initialize native application: {}\n",
            .{error.FailedApplicationLaunch},
        );
    }
    // Create a window
    var window = try bge.Window.create(.{
        .width = Config.WIDTH,
        .height = Config.HEIGHT,
        .title = "ZASTEROIDS",
    });
    defer window.destroy();
    // Initialize keyboard
    var keyboard = bge.Keyboard.init() catch |err| {
        std.process.fatal(
            "[MAIN] failed to initialize keyboard input: {}\n",
            .{err},
        );
    };
    defer keyboard.deinit();

    // MARK: Internal stuff that runs the game
    var stateManager = GameStateManager.init(); // place holder for the engine
    var entityManager = EntityManager.init(&allocator) catch |err| {
        std.process.fatal("[MAIN] failed to initialize entity manager: {}\n", .{err});
    };
    defer entityManager.deinit();

    var renderer = Renderer.init(&allocator, Config.WIDTH, Config.HEIGHT) catch |err| {
        std.process.fatal("[MAIN] failed to initialize renderer: {}\n", .{err});
    };
    defer renderer.deinit();

    // MARK: Main loop
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
        dt = elapsed / Config.F32_NS_PER_S;
        window.processEvents();

        stateManager.update(dt);
        entityManager.update(dt);

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

        renderer.endFrame();

        window.updateWindowPixels(
            renderer.getRawFrameBuffer(),
            Config.WIDTH,
            Config.HEIGHT,
        );

        frameEndTime = std.time.microTimestamp();
        frameDuration = frameEndTime - currentTime;

        sleepTime = Config.TARGET_FRAME_TIME_NS - frameDuration;
        if (sleepTime > 0) {
            // std.debug.print("sleeptime by: {d}\n", .{sleepTime});
            std.Thread.sleep(@intCast(sleepTime));
        } else {
            std.debug.print("Missed frametime by: {d}", .{sleepTime});
        }
    }

    std.debug.print("Application shutting down\n", .{});
}
