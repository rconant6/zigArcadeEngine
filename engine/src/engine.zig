const std = @import("std");

pub const math = @import("math");

pub const rend = @import("renderer");
pub const Renderer = rend.Renderer;

pub const asset = @import("assets");

pub const ecs = @import("ecs");
pub const EntityManager = ecs.EntityManager;

pub const input = @import("input");
pub const InputManager = input.InputManager;
pub const ActionManager = input.ActionManager;

pub const plat = @import("platform");
const Window = plat.Window;

pub const EngineConfig = struct {
    width: i32,
    height: i32,
    title: [:0]const u8,
    targetFps: f32,

    const TARGET_FPS: f32 = 60.0;
    const WIDTH: i32 = 1600;
    const HEIGHT: i32 = 900;
    const NAME: [:0]const u8 = "PLACEHOLDER";

    pub fn toEngineConfig() EngineConfig {
        return EngineConfig{
            .width = WIDTH,
            .height = HEIGHT,
            .title = NAME,
            .targetFps = TARGET_FPS,
        };
    }
    pub fn toEngineNamedConfig(title: [:0]const u8) EngineConfig {
        return EngineConfig{
            .width = WIDTH,
            .height = HEIGHT,
            .title = title,
            .targetFps = TARGET_FPS,
        };
    }
};

pub const Engine = struct {
    allocator: std.mem.Allocator,
    window: plat.Window,
    running: bool,
    config: EngineConfig,
    inputManager: *input.InputManager,
    renderer: rend.Renderer,
    entityManager: ecs.EntityManager,

    pub fn init(allocator: std.mem.Allocator, config: EngineConfig) !Engine {
        const app = plat.c.wb_initApplication();
        if (app == 0) {
            std.process.fatal(
                "[ENGINE] failed to initialize native application: {}\n",
                .{error.FailedApplicationLaunch},
            );
        }

        const window = try Window.create(.{
            .width = @floatFromInt(config.width),
            .height = @floatFromInt(config.height),
            .title = config.title,
        });

        const inputManager = try allocator.create(InputManager);
        inputManager.* = InputManager.init(config.width, config.height) catch |err| {
            std.log.err("[ENGINE] failed to initialize Input Manager: {}\n", .{err});
            return err;
        };

        const entityManager = EntityManager.init(allocator) catch |err| {
            std.log.err("[ENGINE] failed to initialize Entity Manager: {}\n", .{err});
            return err;
        };

        var renderer = Renderer.init(allocator, config.width, config.height) catch |err| {
            std.log.err("[ENGINE] failed to initialize renderer: {}\n", .{err});
            return err;
        };
        renderer.setClearColor(rend.Colors.BLACK);

        return Engine{
            .allocator = allocator,
            .renderer = renderer,
            .inputManager = inputManager,
            .entityManager = entityManager,
            .window = window,
            .config = config,
            .running = true,
        };
    }

    pub fn deinit(self: *Engine) void {
        self.allocator.destroy(self.inputManager);
        self.entityManager.deinit();
        self.renderer.deinit();
        self.window.destroy();
    }

    pub fn createActionManager(self: *Engine, comptime ActionType: type, allocator: std.mem.Allocator) ActionManager(ActionType) {
        return ActionManager(ActionType).init(allocator, self.inputManager);
    }

    pub fn stopRunning(self: *Engine) void {
        self.running = false;
    }

    pub fn run(self: *Engine, game: anytype) !void {
        // var lastTime: i64 = std.time.microTimestamp();
        const dt: f32 = 1.0 / 60.0;
        var inputManager = self.inputManager;

        while (self.running) {
            self.window.processEvents();
            if (self.window.shouldClose()) {
                self.running = false;
                continue;
            }

            inputManager.pollEvents();
            inputManager.processEvents();
            if (inputManager.isKeyPressed(.Esc)) {
                self.running = false;
            }
            // **** THIS IS THE INTERFACE BACK TO THE GAME **** //
            game.update(self, dt);
            // **** THIS IS THE INTERFACE BACK TO THE GAME **** //
            inputManager.update(dt);

            self.renderer.beginFrame();
            self.entityManager.renderSystem(&self.renderer);
            self.renderer.endFrame();

            const rawBytes: []u8 = std.mem.sliceAsBytes(self.renderer.frameBuffer.frontBuffer);
            self.window.updateWindowPixels(
                rawBytes,
                @intCast(self.config.width),
                @intCast(self.config.height),
            );

            // Bottom of loop - timing calculation
            //     const currentTime = std.time.microTimestamp();
            //     const frameDurationUs = currentTime - lastTime;
            //     dt = @as(f32, @floatFromInt(frameDurationUs)) / 1_000_000.0; // Convert to seconds
            //     lastTime = currentTime;

            //     // Optional frame rate limiting
            //     const sleepTimeUs = Config.TARGET_FRAME_TIME_US - frameDurationUs;
            //     if (sleepTimeUs > 0) {
            //         std.debug.print("sleeptime: {d}\n", .{sleepTimeUs});
            //         std.Thread.sleep(@intCast(sleepTimeUs));
            //     } else {
            //         std.debug.print("Missed frametime by: {d}\n", .{sleepTimeUs});
            //     }
            // }
        }
    }
};

// // MARK: External stuff that feeds the game
// var assetManager = AssetManager.init(allocator) catch |err| {
//     std.process.fatal("[MAIN] failed to initialize Asset Manager: {}\n", .{err});
// };
// defer assetManager.deinit();
// assetManager.setFontPath("../../zasteroids/resources/fonts");
//
// // var stateManager = GameStateManager.init();
// // defer stateManager.deinit();

// const fontName = "Orbitron.ttf";
// // var font = try assetManager.loadFont("Silkscreen", "fonts/Silkscreen.ttf");
// // var font = try assetManager.loadFont("Pixelify", "fonts/PixelifySans.ttf");
// // var font = try assetManager.loadFont("SpaceMono", "fonts/SpaceMono.ttf"); // This one has some issues (format?)
// // var font = try assetManager.loadFont("Arcade", "fonts/arcadeFont.ttf");
// var font = try assetManager.loadFont(fontName);
// std.debug.print("[MAIN] loaded {s} font\n", .{fontName});

// const char = 'E';
// if (font.charToGlyph.get(char)) |glyphIndex| {
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

// const ship = try entityManager.addEntityWithConfigs(
//     .{
//         .Triangle = .{
//             .fillColor = rend.Colors.BLUE,
//             .offset = .{ .x = 6, .y = 6 },
//             .outlineColor = rend.Colors.WHITE,
//             .scale = 5,
//             .rotation = 0,
//         },
//     },
//     .{
//         .playerID = 0,
//         .rotationRate = 16,
//         .thrustForce = 5,
//         .shotRate = 4,
//     },
// );
// _ = try entityManager.addComponent(ship.entity, .{ .Velocity = .{ .velocity = V2.ZERO } });
