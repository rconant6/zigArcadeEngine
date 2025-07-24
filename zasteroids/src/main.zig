const std = @import("std");

const plat = @import("platform");
const Window = plat.Window;
const c = plat.c;

const input = @import("input");
const InputManager = input.InputManager;
const ActionManager = input.ActionManager;

const rend = @import("renderer");
const Colors = rend.Colors;
const Point = rend.GamePoint;
const Renderer = rend.Renderer;

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
    const allocator = gpa.allocator();

    // MARK: External stuff that feeds the game
    // Initialize the application
    const app = plat.c.wb_initApplication();
    if (app == 0) {
        std.process.fatal(
            "[MAIN] failed to initialize native application: {}\n",
            .{error.FailedApplicationLaunch},
        );
    }

    // Create a window
    var window = try Window.create(.{
        .width = Config.WIDTH,
        .height = Config.HEIGHT,
        .title = "ZASTEROIDS",
    });
    defer window.destroy();

    var inputManager = InputManager.init(Config.WIDTH, Config.HEIGHT) catch |err| {
        std.process.fatal("[MAIN] failed to initialize Input Manager: {}\n", .{err});
    };
    defer inputManager.deinit();

    const GameActions = enum {
        Quit,
    };
    var gameActions = input.ActionManager(GameActions).init(allocator);
    defer gameActions.deinit();

    // Add quit bindings
    try gameActions.addBinding(.{
        .action = .Quit,
        .source = .{ .Key = .Esc },
    });

    try gameActions.addBinding(.{
        .action = .Quit,
        .source = .{ .MouseButton = .Right },
    });

    try gameActions.addBinding(.{
        .action = .Quit,
        .source = .{ .KeyCombo = .{ .modifier = .Command, .key = .Q } },
    });

    var entityManager = EntityManager.init(allocator) catch |err| {
        std.process.fatal("[MAIN] failed to initialize Entity Manager: {}\n", .{err});
    };
    defer entityManager.deinit();

    var assetManager = AssetManager.init(allocator) catch |err| {
        std.process.fatal("[MAIN] failed to initialize Asset Manager: {}\n", .{err});
    };
    defer assetManager.deinit();
    assetManager.setFontPath("../../zasteroids/resources/fonts");

    var renderer = Renderer.init(allocator, Config.WIDTH, Config.HEIGHT) catch |err| {
        std.process.fatal("[MAIN] failed to initialize renderer: {}\n", .{err});
    };
    renderer.setClearColor(rend.Colors.BLACK);
    defer renderer.deinit();

    // var stateManager = GameStateManager.init();
    // defer stateManager.deinit();

    const fontName = "Orbitron.ttf";
    // var font = try assetManager.loadFont("Silkscreen", "fonts/Silkscreen.ttf");
    // var font = try assetManager.loadFont("Pixelify", "fonts/PixelifySans.ttf");
    // var font = try assetManager.loadFont("SpaceMono", "fonts/SpaceMono.ttf"); // This one has some issues (format?)
    // var font = try assetManager.loadFont("Arcade", "fonts/arcadeFont.ttf");
    var font = try assetManager.loadFont(fontName);
    std.debug.print("[MAIN] loaded {s} font\n", .{fontName});

    const char = 'E';
    if (font.charToGlyph.get(char)) |glyphIndex| {
        if (font.glyphShapes.get(glyphIndex)) |glyph| {
            const firstContourEnd = glyph.contourEnds[0];
            const firstContourPoints = glyph.points[0 .. firstContourEnd + 1];
            var points = try std.ArrayList(Point).initCapacity(allocator, firstContourPoints.len);
            const fontScale = 0.1;
            const aspectRatio = 1.78;
            for (firstContourPoints) |point| {
                const newPoint: Point =
                    .{
                        .x = (point.x * fontScale) / aspectRatio,
                        .y = point.y * fontScale,
                    };
                points.appendAssumeCapacity(newPoint);
            }
            const letter = try entityManager.addEntity();
            _ = try entityManager.addRender(letter.entity, .{ .shapeData = .{ .Polygon = .{
                .vertices = try points.toOwnedSlice(),
                .outlineColor = Colors.NEON_BLUE,
                .center = .{ .x = -0.352, .y = -0.465 },
                .fillColor = null,
            } }, .visible = true });
            _ = try entityManager.addTransform(letter.entity, .{ .transform = .{ .scale = 1.2 } });
        }
    }

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

        inputManager.pollEvents();
        inputManager.processEvents();

        // temp for quitting while building
        if (inputManager.isInputPressed(.{ .Key = .Esc }) or inputManager.isInputPressed(.{ .MouseButton = .Right })) running = false;
        if (inputManager.isInputPressed(.{ .KeyCombo = .{ .modifier = .Command, .key = .Q } })) running = false;
        if (inputManager.isInputPressed(.{ .MouseCombo = .{ .modifier = .Option, .button = .Left } })) running = false;

        renderer.beginFrame();
        entityManager.renderSystem(&renderer);
        renderer.endFrame();

        inputManager.update(dt);
        const rawBytes: []u8 = std.mem.sliceAsBytes(renderer.frameBuffer.frontBuffer);
        window.updateWindowPixels(
            rawBytes,
            Config.WIDTH,
            Config.HEIGHT,
        );
        // inputHandler.update(dt);
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
