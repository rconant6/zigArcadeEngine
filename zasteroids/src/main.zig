const std = @import("std");

const platform = @import("platform");

const rend = @import("renderer");
const Renderer = rend.Renderer;

const ecs = @import("ecs");
const EntityManager = ecs.EntityManager;

const asset = @import("asset");
const AssetManager = asset.AssetManager;

const Config = struct {
    const TARGET_FPS: f32 = 60.0;
    const TARGET_FRAME_TIME_US: i64 = @intFromFloat((1.0 / TARGET_FPS) * 1_000_000);
    const WIDTH: i32 = 1600;
    const HEIGHT: i32 = 900;
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocator = gpa.allocator();

    // MARK: External stuff that feeds the game
    // Initialize the application
    const app = platform.c.wb_initApplication();
    if (app == 0) {
        std.process.fatal(
            "[MAIN] failed to initialize native application: {}\n",
            .{error.FailedApplicationLaunch},
        );
    }
    // Create a window
    var window = try platform.Window.create(.{
        .width = Config.WIDTH,
        .height = Config.HEIGHT,
        .title = "ZASTEROIDS",
    });
    defer window.destroy();
    // Initialize keyboard
    var keyboard = platform.Keyboard.init() catch |err| {
        std.process.fatal(
            "[MAIN] failed to initialize keyboard input: {}\n",
            .{err},
        );
    };
    defer keyboard.deinit();

    // MARK: Internal stuff that runs the game will be absorbed by the 'engine'
    // var inputManager = InputManager.init();
    // defer inputManager.deinit();

    // var stateManager = GameStateManager.init();
    // defer stateManager.deinit();

    var entityManager = EntityManager.init(&allocator) catch |err| {
        std.process.fatal("[MAIN] failed to initialize entity manager: {}\n", .{err});
    };
    defer entityManager.deinit();

    var assetManager = AssetManager.init(&allocator) catch |err| {
        std.process.fatal("[MAIN] failed to initialize asset manager: {}\n", .{err});
    };
    defer assetManager.deinit();

    var renderer = Renderer.init(&allocator, Config.WIDTH, Config.HEIGHT) catch |err| {
        std.process.fatal("[MAIN] failed to initialize renderer: {}\n", .{err});
    };
    defer renderer.deinit();

    // MARK: Main loop
    var running = true;
    var lastTime: i64 = std.time.microTimestamp();
    var dt: f32 = 1.0 / 60.0;

    while (running) {
        window.processEvents();
        if (window.shouldClose()) {
            running = false;
            continue;
        }

        // Check for keyboard input
        while (keyboard.pollEvent()) |keyEvent| {
            // temporary quitting
            if (keyEvent.keyCode == .Esc) {
                std.debug.print("[MAIN] shutting down\n", .{});
                running = false;
            }

            // this should return a bool? to do a quit? else move keep going
            // stateManager.processKeyEvent(keyEvent);
            // inputManager.updateState(keyEvent);
        }

        // stateManager.update(dt);
        // entityManager.inputSystem(&inputManager, dt);
        // inputManager.endFrame();

        // entityManager.physicsSystem(dt);

        // renderer.beginFrame();
        // entityManager.renderSystem(&renderer);
        // renderer.endFrame();

        window.updateWindowPixels(
            renderer.getRawFrameBuffer(),
            Config.WIDTH,
            Config.HEIGHT,
        );

        // Bottom of loop - timing calculation
        const currentTime = std.time.microTimestamp();
        const frameDurationUs = currentTime - lastTime;
        dt = @as(f32, @floatFromInt(frameDurationUs)) / 1_000_000.0; // Convert to seconds
        lastTime = currentTime;

        // Optional frame rate limiting
        const sleepTimeUs = Config.TARGET_FRAME_TIME_US - frameDurationUs;
        if (sleepTimeUs > 0) {
            // std.debug.print("sleeptime: {d}\n", .{sleepTimeUs});
            std.Thread.sleep(@intCast(sleepTimeUs));
        } else {
            std.debug.print("Missed frametime by: {d}\n", .{sleepTimeUs});
        }
    }
}
