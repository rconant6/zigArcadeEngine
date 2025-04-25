const std = @import("std");

const GameStateManager = @import("../managers/gameStateManager.zig").GameStateManager;
const InputManager = @import("../managers/inputManager.zig").InputManager;

const InputSystem = @import("../systems/inputSystem.zig").InputSystem;

// TODO: remove this is debug code only
const InputComponent = @import("../systems/inputSystem.zig").InputComponent;
// END DEBUG CODE

pub const Engine = struct {
    arena: std.heap.ArenaAllocator,
    isRunning: bool,
    targetFPS: u32,

    stateManager: GameStateManager,
    inputManager: InputManager,

    inputSystem: InputSystem,

    inputComponents: std.ArrayList(InputComponent),

    pub fn init(allocator: *std.mem.Allocator) !Engine {
        std.debug.print("[ENGINE] intializing...\n", .{});
        var engine = Engine{
            .arena = std.heap.ArenaAllocator.init(allocator.*),
            .isRunning = true,
            .targetFPS = 60, // FPS

            .stateManager = undefined,
            .inputManager = undefined,
            .inputSystem = InputSystem.init(allocator),

            // TODO: remove this is debug code only
            .inputComponents = std.ArrayList(InputComponent).init(allocator.*),
            // END DEBUG CODE

        };

        engine.stateManager = GameStateManager.init(&engine);
        engine.inputManager = try InputManager.init(allocator, &engine.inputSystem);

        // TODO: remove debug code
        engine.inputComponents.append(InputComponent.init(allocator)) catch {};
        engine.inputComponents.append(InputComponent.init(allocator)) catch {};

        return engine;
    }
    pub fn deinit(self: *Engine) void {
        std.debug.print("[ENGINE] de-intializing...\n", .{});
        self.arena.deinit();
    }

    pub fn run(self: *Engine) !void {
        std.debug.print("[ENGINE] running\n", .{});
        // const frameDuration = std.time.ms_per_s / self.targetFPS; // 1_000_000 PS / 60 FPS
        var frameStart: i64 = 0;
        var frameEnd: i64 = 0;
        var sleepDuration: i64 = 0;
        var elapsed: i64 = 0;
        var frameCount: i64 = 0;
        while (self.isRunning) : (frameCount += 1) {
            std.debug.print("[ENGINE] frameCount: {d}\n", .{frameCount});
            frameStart = std.time.microTimestamp();
            try self.update(@intCast(frameStart));
            try self.render();
            frameEnd = std.time.microTimestamp();
            elapsed = frameEnd - frameStart;
            // sleepDuration = frameDuration - elapsed;
            sleepDuration = 1_000_000;

            if (sleepDuration > 0) {
                std.debug.print("sleepDuration {d}\n", .{sleepDuration});
                std.Thread.sleep(@intCast(sleepDuration * std.time.ms_per_s));
            }

            if (frameCount >= 10) break;
        }
    }

    fn update(self: *Engine, frameStart: u64) !void {
        std.debug.print("[ENGINE] - update\n", .{});
        // Input updates
        try self.inputManager.update();
        self.inputSystem.update(&self.inputComponents, frameStart) catch {
            std.debug.print("whoops\n", .{});
        };
        self.stateManager.update(10.0);
    }

    fn render(self: *Engine) !void {
        _ = self;
        std.debug.print("[ENGINE] - render\n", .{});
        // do the rendering stuff
    }
};
