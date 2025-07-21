const std = @import("std");

const plat = @import("platform");
const InputHandler = plat.InputHandler;
const InputEvent = plat.InputEvent;
const Keyboard = plat.Keyboard;
const Mouse = plat.Mouse;
const Window = plat.Window;
const c = plat.c;

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
    var allocator = gpa.allocator();

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

    // Initialize keyboard
    var keyboard = Keyboard.init() catch |err| {
        std.process.fatal(
            "[MAIN] failed to initialize keyboard input: {}\n",
            .{err},
        );
    };
    defer keyboard.deinit();

    // Initialize mouse
    var mouse = Mouse.init() catch |err| {
        std.process.fatal(
            "[MAIN] failed to initialize mouse input: {}\n",
            .{err},
        );
    };
    testMouseBridgeLinks();
    defer mouse.deinit();

    var inputHandler = InputHandler.init();

    var entityManager = EntityManager.init(&allocator) catch |err| {
        std.process.fatal("[MAIN] failed to initialize entity manager: {}\n", .{err});
    };
    defer entityManager.deinit();

    var assetManager = AssetManager.init(&allocator) catch |err| {
        std.process.fatal("[MAIN] failed to initialize asset manager: {}\n", .{err});
    };
    defer assetManager.deinit();
    assetManager.setFontPath("../../zasteroids/resources/fonts");

    var renderer = Renderer.init(&allocator, Config.WIDTH, Config.HEIGHT) catch |err| {
        std.process.fatal("[MAIN] failed to initialize renderer: {}\n", .{err});
    };
    renderer.setClearColor(rend.Colors.BLACK);
    defer renderer.deinit();

    // var inputManager = InputManager.init();
    // defer inputManager.deinit();

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

        // Check for keyboard input
        while (keyboard.pollEvent()) |keyEvent| {
            // temporary quitting
            if (keyEvent.keyCode == .Esc) {
                std.debug.print("[MAIN] shutting down\n", .{});
                running = false;
            } else {
                std.debug.print("InputState: {any} for key: {any}\n", .{ inputHandler.getKeyState(keyEvent.keyCode), keyEvent.keyCode });
                // std.debug.print("[MAIN] KeyCode: {any}\n", .{keyEvent.keyCode});
                inputHandler.processInputEvent(InputEvent{ .key = keyEvent });
            }
        }

        renderer.beginFrame();
        entityManager.renderSystem(&renderer);
        renderer.endFrame();

        const rawBytes: []u8 = std.mem.sliceAsBytes(renderer.frameBuffer.frontBuffer);
        window.updateWindowPixels(
            rawBytes,
            Config.WIDTH,
            Config.HEIGHT,
        );
        inputHandler.update(dt);
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

pub fn testMouseBridgeLinks() void {
    std.debug.print("[MOUSE TEST] Testing all C bridge functions...\n", .{});

    // Basic lifecycle
    _ = c.m_startMouseMonitoring();
    c.m_stopMouseMonitoring();

    // Event polling
    var batch: c.mMouseEventBatch = undefined;
    _ = c.m_pollMouseEventBatch(&batch);
    _ = c.m_hasMouseEvents();
    c.m_clearMouseEvents();

    // State queries
    var state: c.mMouseState = undefined;
    _ = c.m_getMouseState(&state);
    _ = c.m_isButtonPressed(c.M_BUTTON_LEFT);

    var gameX: f32 = undefined;
    var gameY: f32 = undefined;
    _ = c.m_getMousePosition(&gameX, &gameY);

    // Gesture queries
    _ = c.m_wasButtonClicked(c.M_BUTTON_LEFT);
    _ = c.m_wasButtonDoubleClicked(c.M_BUTTON_LEFT);

    var deltaX: f32 = undefined;
    var deltaY: f32 = undefined;
    _ = c.m_getMouseDelta(&deltaX, &deltaY);

    var scrollX: f32 = undefined;
    var scrollY: f32 = undefined;
    _ = c.m_getScrollData(&scrollX, &scrollY);

    // Configuration
    c.m_setWindowDimensions(800, 600);
    c.m_setDoubleClickTime(500);
    c.m_setMouseSensitivity(1.0);

    // Test enum values compile
    _ = c.M_BUTTON_PRESS;
    _ = c.M_BUTTON_RELEASE;
    _ = c.M_MOVE;
    _ = c.M_SCROLL;
    _ = c.M_ENTER_WINDOW;
    _ = c.M_EXIT_WINDOW;

    _ = c.M_BUTTON_LEFT;
    _ = c.M_BUTTON_RIGHT;
    _ = c.M_BUTTON_MIDDLE;
    _ = c.M_BUTTON_EXTRA1;
    _ = c.M_BUTTON_EXTRA2;

    std.debug.print("[MOUSE TEST] All functions linked successfully!\n", .{});
}
