const std = @import("std");

const platform = @import("platform");

const rend = @import("renderer");
const Renderer = rend.Renderer;
const Colors = rend.Colors;
const Point = rend.GamePoint;

const ecs = @import("ecs");
const EntityManager = ecs.EntityManager;

const asset = @import("asset");
const AssetManager = asset.AssetManager;

const math = @import("math");
const V2 = math.V2;

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

    // const fontName = "Orbitron";
    // // var font = try assetManager.loadFont("Silkscreen", "fonts/Silkscreen.ttf");
    // // var font = try assetManager.loadFont("Pixelify", "fonts/PixelifySans.ttf");
    // // var font = try assetManager.loadFont("SpaceMono", "fonts/SpaceMono.ttf"); // This one has some issues (format?)
    // // var font = try assetManager.loadFont("Arcade", "fonts/arcadeFont.ttf");
    // var font = try assetManager.loadFont(fontName, "fonts/Orbitron.ttf");
    // std.debug.print("[MAIN] loaded {s} font\n", .{fontName});

    // const c = 'Z';
    // if (font.charToGlyph.get(c)) |glyphIndex| {
    //     if (font.glyphShapes.get(glyphIndex)) |glyph| {
    //         const firstContourEnd = glyph.contourEnds[0];
    //         const firstContourPoints = glyph.points[0 .. firstContourEnd + 1];
    //         var points = try std.ArrayList(Point).initCapacity(allocator, firstContourPoints.len);
    //         const fontScale = 0.1;
    //         const aspectRatio = 1.78;
    //         for (firstContourPoints) |point| {
    //             const newPoint: Point =
    //                 .{
    //                     .x = (point.x * fontScale) / aspectRatio,
    //                     .y = point.y * fontScale,
    //                 };
    //             points.appendAssumeCapacity(newPoint);
    //         }
    //         const letter = try entityManager.addEntity();
    //         _ = try entityManager.addRender(letter.entity, .{ .shapeData = .{ .Polygon = .{
    //             .vertices = try points.toOwnedSlice(),
    //             .outlineColor = Colors.NEON_BLUE,
    //             .center = .{ .x = -0.352, .y = -0.465 },
    //             .fillColor = null,
    //         } }, .visible = true });
    //         _ = try entityManager.addTransform(letter.entity, .{ .transform = .{ .scale = 1.2 } });
    //     }
    // }

    const ship = try entityManager.addEntityWithConfigs(
        .{
            .Triangle = .{
                .fillColor = rend.Colors.BLUE,
                .offset = .{ .x = 6, .y = 6 },
                .outlineColor = rend.Colors.WHITE,
                .scale = 5,
                .rotation = 0,
            },
        },
        .{
            .playerID = 0,
            .rotationRate = 16,
            .thrustForce = 5,
            .shotRate = 4,
        },
    );
    _ = try entityManager.addComponent(ship.entity, .{ .Velocity = .{ .velocity = V2.ZERO } });

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

        renderer.beginFrame();
        entityManager.renderSystem(&renderer);
        renderer.endFrame();

        const rawBytes: []u8 = std.mem.sliceAsBytes(renderer.frameBuffer.frontBuffer);
        window.updateWindowPixels(
            rawBytes,
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
            std.debug.print("sleeptime: {d}\n", .{sleepTimeUs});
            std.Thread.sleep(@intCast(sleepTimeUs));
        } else {
            std.debug.print("Missed frametime by: {d}\n", .{sleepTimeUs});
        }
    }
}
