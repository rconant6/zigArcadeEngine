const std = @import("std");

const bge = @import("bridge.zig");
const KeyCodes = bge.GameKeyCode;

const gsm = @import("gameStateManager.zig");
const GameStateManager = gsm.GameStateManager;

const ecs = @import("ecs.zig");
const EntityManager = ecs.EntityManager;

const rend = @import("renderer");
// const Circle = rend.Circle;
// const Color = rend.Color;
// const Line = rend.Line;
// const Point = rend.Point;
// const Rectangle = rend.Rectangle;
const Renderer = rend.Renderer;
// const ScreenPoint = rend.ScreenPoint;
// const Triangle = rend.Triangle;
// const Polygon = rend.Polygon;

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

    // Add this code to your main.zig after creating the entityManager and before the main loop

    // MARK: Create Comprehensive Test Entities for Transform System
    std.debug.print("[MAIN] Creating comprehensive test entities...\n", .{});

    // ===== POSITION-ONLY ENTITIES =====
    // Entity 1: Red Circle (right side)
    const e1 = try entityManager.createEntity();
    const transform1 = ecs.ComponentType{ .Transform = .{ .transform = rend.Transform{ .pos = rend.Point.init(0.8, 0.6) } } };
    const circle1 = rend.Circle{
        .origin = rend.Point.init(0.0, 0.0),
        .radius = 0.12,
        .fillColor = rend.Color.init(1.0, 0.2, 0.2, 1.0),
        .outlineColor = rend.Color.init(0.8, 0.0, 0.0, 1.0),
    };
    const render1 = ecs.ComponentType{ .Render = .{ .shapeData = rend.ShapeData{ .Circle = circle1 }, .visible = true } };
    _ = try entityManager.addComponent(e1, transform1);
    _ = try entityManager.addComponent(e1, render1);

    // Entity 2: Green Rectangle (top-left)
    const e2 = try entityManager.createEntity();
    const transform2 = ecs.ComponentType{ .Transform = .{ .transform = rend.Transform{ .pos = rend.Point.init(-0.7, 0.8) } } };
    const rect2 = rend.Rectangle{
        .center = rend.Point.init(0.0, 0.0),
        .halfWidth = 0.1,
        .halfHeight = 0.06,
        .fillColor = rend.Color.init(0.2, 1.0, 0.2, 1.0),
        .outlineColor = rend.Color.init(0.0, 0.6, 0.0, 1.0),
    };
    const render2 = ecs.ComponentType{ .Render = .{ .shapeData = rend.ShapeData{ .Rectangle = rect2 }, .visible = true } };
    _ = try entityManager.addComponent(e2, transform2);
    _ = try entityManager.addComponent(e2, render2);

    // Entity 3: Blue Triangle (bottom)
    const e3 = try entityManager.createEntity();
    const transform3 = ecs.ComponentType{ .Transform = .{ .transform = rend.Transform{ .pos = rend.Point.init(0.0, -0.8) } } };
    var triangle_points3 = [_]rend.Point{
        rend.Point.init(0.0, 0.12),
        rend.Point.init(-0.1, -0.08),
        rend.Point.init(0.1, -0.08),
    };
    const triangle3 = rend.Triangle{
        .vertices = &triangle_points3,
        .fillColor = rend.Color.init(0.2, 0.2, 1.0, 1.0),
        .outlineColor = rend.Color.init(0.0, 0.0, 0.8, 1.0),
    };
    const render3 = ecs.ComponentType{ .Render = .{ .shapeData = rend.ShapeData{ .Triangle = triangle3 }, .visible = true } };
    _ = try entityManager.addComponent(e3, transform3);
    _ = try entityManager.addComponent(e3, render3);

    // ===== SCALE-ONLY ENTITIES =====
    // Entity 4: Large Yellow Circle (center-left)
    const e4 = try entityManager.createEntity();
    const transform4 = ecs.ComponentType{ .Transform = .{ .transform = rend.Transform{ .pos = rend.Point.init(-0.4, 0.0), .scale = 2.5 } } };
    const circle4 = rend.Circle{
        .origin = rend.Point.init(0.0, 0.0),
        .radius = 0.08,
        .fillColor = rend.Color.init(1.0, 1.0, 0.3, 1.0),
        .outlineColor = rend.Color.init(0.8, 0.8, 0.0, 1.0),
    };
    const render4 = ecs.ComponentType{ .Render = .{ .shapeData = rend.ShapeData{ .Circle = circle4 }, .visible = true } };
    _ = try entityManager.addComponent(e4, transform4);
    _ = try entityManager.addComponent(e4, render4);

    // Entity 5: Tiny Magenta Rectangle (center)
    const e5 = try entityManager.createEntity();
    const transform5 = ecs.ComponentType{ .Transform = .{ .transform = rend.Transform{ .pos = rend.Point.init(0.0, 0.0), .scale = 0.4 } } };
    const rect5 = rend.Rectangle{
        .center = rend.Point.init(0.0, 0.0),
        .halfWidth = 0.15,
        .halfHeight = 0.1,
        .fillColor = rend.Color.init(1.0, 0.3, 1.0, 1.0),
        .outlineColor = rend.Color.init(0.8, 0.0, 0.8, 1.0),
    };
    const render5 = ecs.ComponentType{ .Render = .{ .shapeData = rend.ShapeData{ .Rectangle = rect5 }, .visible = true } };
    _ = try entityManager.addComponent(e5, transform5);
    _ = try entityManager.addComponent(e5, render5);

    // ===== ROTATION-ONLY ENTITIES =====
    // Entity 6: Rotated Cyan Rectangle (top-right, 30°)
    const e6 = try entityManager.createEntity();
    const transform6 = ecs.ComponentType{
        .Transform = .{
            .transform = rend.Transform{
                .pos = rend.Point.init(0.6, 0.7),
                .rot = std.math.pi / 6.0, // 30 degrees
            },
        },
    };
    const rect6 = rend.Rectangle{
        .center = rend.Point.init(0.0, 0.0),
        .halfWidth = 0.12,
        .halfHeight = 0.05,
        .fillColor = rend.Color.init(0.3, 1.0, 1.0, 1.0),
        .outlineColor = rend.Color.init(0.0, 0.8, 0.8, 1.0),
    };
    const render6 = ecs.ComponentType{ .Render = .{ .shapeData = rend.ShapeData{ .Rectangle = rect6 }, .visible = true } };
    _ = try entityManager.addComponent(e6, transform6);
    _ = try entityManager.addComponent(e6, render6);

    // Entity 7: Rotated Orange Triangle (left side, 135°)
    const e7 = try entityManager.createEntity();
    const transform7 = ecs.ComponentType{
        .Transform = .{
            .transform = rend.Transform{
                .pos = rend.Point.init(-0.6, -0.3),
                .rot = 3.0 * std.math.pi / 4.0, // 135 degrees
            },
        },
    };
    var triangle_points7 = [_]rend.Point{
        rend.Point.init(0.0, 0.1),
        rend.Point.init(-0.08, -0.08),
        rend.Point.init(0.08, -0.08),
    };
    const triangle7 = rend.Triangle{
        .vertices = &triangle_points7,
        .fillColor = rend.Color.init(1.0, 0.6, 0.2, 1.0),
        .outlineColor = rend.Color.init(0.8, 0.4, 0.0, 1.0),
    };
    const render7 = ecs.ComponentType{ .Render = .{ .shapeData = rend.ShapeData{ .Triangle = triangle7 }, .visible = true } };
    _ = try entityManager.addComponent(e7, transform7);
    _ = try entityManager.addComponent(e7, render7);

    // ===== SCALE + ROTATION ENTITIES =====
    // Entity 8: Large Rotated Pink Circle (bottom-right, 2x + 45°)
    const e8 = try entityManager.createEntity();
    const transform8 = ecs.ComponentType{
        .Transform = .{
            .transform = rend.Transform{
                .pos = rend.Point.init(0.5, -0.5),
                .rot = std.math.pi / 4.0, // 45 degrees
                .scale = 1.8,
            },
        },
    };
    const circle8 = rend.Circle{
        .origin = rend.Point.init(0.0, 0.0),
        .radius = 0.07,
        .fillColor = rend.Color.init(1.0, 0.5, 0.8, 1.0),
        .outlineColor = rend.Color.init(0.8, 0.2, 0.6, 1.0),
    };
    const render8 = ecs.ComponentType{ .Render = .{ .shapeData = rend.ShapeData{ .Circle = circle8 }, .visible = true } };
    _ = try entityManager.addComponent(e8, transform8);
    _ = try entityManager.addComponent(e8, render8);

    // Entity 9: Small Rotated Lime Rectangle (top-center, 0.6x + 60°)
    const e9 = try entityManager.createEntity();
    const transform9 = ecs.ComponentType{
        .Transform = .{
            .transform = rend.Transform{
                .pos = rend.Point.init(0.2, 0.6),
                .rot = std.math.pi / 3.0, // 60 degrees
                .scale = 0.6,
            },
        },
    };
    const rect9 = rend.Rectangle{
        .center = rend.Point.init(0.0, 0.0),
        .halfWidth = 0.14,
        .halfHeight = 0.08,
        .fillColor = rend.Color.init(0.6, 1.0, 0.2, 1.0),
        .outlineColor = rend.Color.init(0.4, 0.8, 0.0, 1.0),
    };
    const render9 = ecs.ComponentType{ .Render = .{ .shapeData = rend.ShapeData{ .Rectangle = rect9 }, .visible = true } };
    _ = try entityManager.addComponent(e9, transform9);
    _ = try entityManager.addComponent(e9, render9);

    // ===== POLYGON TESTS =====
    // Entity 10: Rotated Pentagon (right side, 72°)
    const e10 = try entityManager.createEntity();
    const transform10 = ecs.ComponentType{
        .Transform = .{
            .transform = rend.Transform{
                .pos = rend.Point.init(0.7, -0.2),
                .rot = 2.0 * std.math.pi / 5.0, // 72 degrees (1/5 rotation)
                .scale = 1.2,
            },
        },
    };
    var polygon_points10 = [_]rend.Point{
        rend.Point.init(0.0, 0.08), // Top
        rend.Point.init(0.06, 0.03), // Top-right
        rend.Point.init(0.04, -0.04), // Bottom-right
        rend.Point.init(-0.04, -0.04), // Bottom-left
        rend.Point.init(-0.06, 0.03), // Top-left
    };
    const polygon10 = rend.Polygon{
        .vertices = &polygon_points10,
        .center = rend.Point.init(0.0, 0.0),
        .fillColor = rend.Color.init(0.8, 0.4, 1.0, 1.0),
        .outlineColor = rend.Color.init(0.6, 0.2, 0.8, 1.0),
    };
    const render10 = ecs.ComponentType{ .Render = .{ .shapeData = rend.ShapeData{ .Polygon = polygon10 }, .visible = true } };
    _ = try entityManager.addComponent(e10, transform10);
    _ = try entityManager.addComponent(e10, render10);

    // Entity 11: Hexagon with extreme transforms (left-center, 3x + 90°)
    const e11 = try entityManager.createEntity();
    const transform11 = ecs.ComponentType{
        .Transform = .{
            .transform = rend.Transform{
                .pos = rend.Point.init(-0.3, 0.4),
                .rot = std.math.pi / 2.0, // 90 degrees
                .scale = 3.0, // Very large
            },
        },
    };
    var polygon_points11 = [_]rend.Point{
        rend.Point.init(0.0, 0.04), // Top
        rend.Point.init(0.035, 0.02), // Top-right
        rend.Point.init(0.035, -0.02), // Bottom-right
        rend.Point.init(0.0, -0.04), // Bottom
        rend.Point.init(-0.035, -0.02), // Bottom-left
        rend.Point.init(-0.035, 0.02), // Top-left
    };
    const polygon11 = rend.Polygon{
        .vertices = &polygon_points11,
        .center = rend.Point.init(0.0, 0.0),
        .fillColor = rend.Color.init(0.4, 0.8, 0.6, 1.0),
        .outlineColor = rend.Color.init(0.2, 0.6, 0.4, 1.0),
    };
    const render11 = ecs.ComponentType{ .Render = .{ .shapeData = rend.ShapeData{ .Polygon = polygon11 }, .visible = true } };
    _ = try entityManager.addComponent(e11, transform11);
    _ = try entityManager.addComponent(e11, render11);

    // ===== EDGE CASE TESTS =====
    // Entity 12: Zero-scale entity (should be invisible)
    const e12 = try entityManager.createEntity();
    const transform12 = ecs.ComponentType{
        .Transform = .{
            .transform = rend.Transform{
                .pos = rend.Point.init(0.0, 0.3),
                .scale = 0.0, // Zero scale
            },
        },
    };
    const circle12 = rend.Circle{
        .origin = rend.Point.init(0.0, 0.0),
        .radius = 0.1,
        .fillColor = rend.Color.init(1.0, 0.0, 1.0, 1.0),
        .outlineColor = rend.Color.init(0.8, 0.0, 0.8, 1.0),
    };
    const render12 = ecs.ComponentType{ .Render = .{ .shapeData = rend.ShapeData{ .Circle = circle12 }, .visible = true } };
    _ = try entityManager.addComponent(e12, transform12);
    _ = try entityManager.addComponent(e12, render12);

    // Entity 13: 360° rotation (should look normal)
    const e13 = try entityManager.createEntity();
    const transform13 = ecs.ComponentType{
        .Transform = .{
            .transform = rend.Transform{
                .pos = rend.Point.init(0.4, 0.3),
                .rot = 2.0 * std.math.pi, // 360 degrees
            },
        },
    };
    var triangle_points13 = [_]rend.Point{
        rend.Point.init(0.0, 0.08),
        rend.Point.init(-0.07, -0.06),
        rend.Point.init(0.07, -0.06),
    };
    const triangle13 = rend.Triangle{
        .vertices = &triangle_points13,
        .fillColor = rend.Color.init(0.7, 0.7, 0.3, 1.0),
        .outlineColor = rend.Color.init(0.5, 0.5, 0.1, 1.0),
    };
    const render13 = ecs.ComponentType{ .Render = .{ .shapeData = rend.ShapeData{ .Triangle = triangle13 }, .visible = true } };
    _ = try entityManager.addComponent(e13, transform13);
    _ = try entityManager.addComponent(e13, render13);

    // Entity 14: Invisible entity (has components but not visible)
    const e14 = try entityManager.createEntity();
    const transform14 = ecs.ComponentType{ .Transform = .{ .transform = rend.Transform{ .pos = rend.Point.init(-0.2, -0.6) } } };
    const rect14 = rend.Rectangle{
        .center = rend.Point.init(0.0, 0.0),
        .halfWidth = 0.1,
        .halfHeight = 0.1,
        .fillColor = rend.Color.init(1.0, 1.0, 1.0, 1.0),
        .outlineColor = rend.Color.init(0.0, 0.0, 0.0, 1.0),
    };
    const render14 = ecs.ComponentType{ .Render = .{ .shapeData = rend.ShapeData{ .Rectangle = rect14 }, .visible = false } };
    _ = try entityManager.addComponent(e14, transform14);
    _ = try entityManager.addComponent(e14, render14);

    // Entity 15: Only Transform (no render - should be ignored)
    const e15 = try entityManager.createEntity();
    const transform15 = ecs.ComponentType{ .Transform = .{ .transform = rend.Transform{ .pos = rend.Point.init(0.8, -0.8) } } };
    _ = try entityManager.addComponent(e15, transform15);

    // Entity 16: Only Render (no transform - should be ignored)
    const e16 = try entityManager.createEntity();
    const circle16 = rend.Circle{
        .origin = rend.Point.init(0.0, 0.0),
        .radius = 0.1,
        .fillColor = rend.Color.init(0.5, 0.5, 0.5, 1.0),
        .outlineColor = null,
    };
    const render16 = ecs.ComponentType{ .Render = .{ .shapeData = rend.ShapeData{ .Circle = circle16 }, .visible = true } };
    _ = try entityManager.addComponent(e16, render16);

    std.debug.print("[MAIN] Created 16 comprehensive test entities:\n", .{});
    std.debug.print("[MAIN] - 3 position-only entities\n", .{});
    std.debug.print("[MAIN] - 2 scale-only entities\n", .{});
    std.debug.print("[MAIN] - 2 rotation-only entities\n", .{});
    std.debug.print("[MAIN] - 2 scale+rotation entities\n", .{});
    std.debug.print("[MAIN] - 2 polygon tests\n", .{});
    std.debug.print("[MAIN] - 3 edge case tests\n", .{});
    std.debug.print("[MAIN] - 2 component mismatch tests\n", .{});
    std.debug.print("[MAIN] Expected visible entities: 12\n", .{});

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
        entityManager.renderSystem(&renderer);
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

    std.debug.print("[MAIN] Application shutting down\n", .{});
}
