const std = @import("std");
const gss = @import("gameStates.zig");

const GameState = gss.GameState;
const PlayingState = gss.PlayingState;
const MenuState = gss.MenuState;
const PausedState = gss.PausedState;
const GameOverState = gss.GameOverState;

const StateTransitions = enum {
    MenuToPlay,
    PauseToPlay,
    PauseToMenu,
    PlayToMenu,
    PlayToPause,
    PlayToGameOver,
    GameOverToMenu,
};

pub const GameStateContext = struct {
    // hold what needs to be passed to start a stage
    // this probably collects alot of optional stuff
    // that each GameState will copy/set in its enter function
    // exit can take a pointer to update it
};

pub const GameStateManager = struct {
    current: GameState,
    // ecs: ECS, // not started yet
    // other things needed
    pub fn init() GameStateManager {
        return GameStateManager{
            .current = gss.GameState{ .PlayingState = gss.PlayingState{} },
        };
    }
    pub fn deinit(self: *GameStateManager) void {
        _ = self;
    }

    pub fn update(self: *GameStateManager, dt: f32) void {
        // std.debug.print("[GAMESTATEMANAGER] - update\n", .{});
        self.current.update(dt);
    }

    pub fn changeState(self: *GameStateManager, stateTrans: StateTransitions) void {
        var newGameState: GameState = undefined;
        switch (stateTrans) {
            .MenuToPlay => {
                // create a new game
                newGameState = GameState{ .PlayingState = PlayingState{} };
            },
            .PauseToPlay => {
                // turn on everything paused again
            },
            .PauseToMenu => {
                // kill the old gamestate
            },
            .PlayToMenu => {
                // kill the old game state
            },
            .PlayToPause => {
                // turn off all the game systems
            },
            .PlayToGameOver => {
                // kill the systems
                // remember some state for stats?
            },
            .GameOverToMenu => {
                // kill the old game state and reset anew
            },
        }

        var ctx: GameStateContext = GameStateContext{};
        self.current.exit(&ctx);
        self.current = newGameState;
        self.current.enter(ctx);
    }
};
