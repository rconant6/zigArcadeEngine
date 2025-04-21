const std = @import("std");
const gss = @import("../core/state.zig");

const Engine = @import("../core/engine.zig").Engine;

const GameState = gss.GameState;

pub const GameStateManager = struct {
    engine: *Engine,
    current: GameState,
    // ecs: ECS, // not started yet
    // other things needed
    pub fn init(engine: *Engine) GameStateManager {
        return GameStateManager{
            .engine = engine,
            .current = gss.GameState{ .PlayingState = gss.PlayingState{} },
        };
    }

    pub fn update(self: *GameStateManager, dt: f32) void {
        std.debug.print("[GAMESTATEMANAGER] - update\n", .{});
        self.current.update(dt);
    }
};
