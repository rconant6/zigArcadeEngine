const std = @import("std");

pub const MenuState = struct {
    // game gets setup and waits for game start
    // add the 4 required functions plus whatever else is needed

    pub fn enter(self: *MenuState, ctx: GameStateContext) void {
        std.debug.print("[MENUSTATE] - enter\n", .{});
        _ = self;
        _ = ctx;
        // do what needs to be done
    }

    pub fn exit(self: *MenuState) void {
        std.debug.print("[MENUSTATE] - exit\n", .{});
        _ = self;
        // do what needs to be done
    }

    pub fn update(self: *MenuState, dt: f32) void {
        std.debug.print("[MENUSTATE] - update\n", .{});
        _ = self;
        _ = dt;
        // do what needs to be done
    }
    pub fn handleInput(self: *MenuState, input: InputComponent) void {
        std.debug.print("[MENUSTATE] - handleInput\n", .{});
        _ = self;
        _ = input;
        // do what needs to be done
    }
};

pub const PlayingState = struct {
    pub fn enter(self: *PlayingState, ctx: GameStateContext) void {
        std.debug.print("[PLAYINGSTATE] - enter\n", .{});
        _ = self;
        _ = ctx;
        // do what needs to be done
    }

    pub fn exit(self: *PlayingState) void {
        std.debug.print("[PLAYINGSTATE] - exit\n", .{});
        _ = self;
        // do what needs to be done
    }

    pub fn update(self: *PlayingState, dt: f32) void {
        std.debug.print("[PLAYINGSTATE] - update\n", .{});
        _ = self;
        _ = dt;
        // do what needs to be done
    }
    pub fn handleInput(self: *PlayingState, input: InputComponent) void {
        std.debug.print("[PLAYINGSTATE] - handleInput\n", .{});
        _ = self;
        _ = input;
        // do what needs to be done
    }
};

pub const PausedState = struct {
    pub fn enter(self: *PausedState, ctx: GameStateContext) void {
        std.debug.print("[PAUSEDSTATE] - enter\n", .{});
        _ = self;
        _ = ctx;
        // do what needs to be done
    }

    pub fn exit(self: *PausedState) void {
        std.debug.print("[PAUSEDSTATE] - exit\n", .{});
        _ = self;
        // do what needs to be done
    }

    pub fn update(self: *PausedState, dt: f32) void {
        std.debug.print("[PAUSEDSTATE] - update\n", .{});
        _ = self;
        _ = dt;
        // do what needs to be done
    }
    pub fn handleInput(self: *PausedState, input: InputComponent) void {
        std.debug.print("[PAUSEDSTATE] - handleInput\n", .{});
        _ = self;
        _ = input;
        // do what needs to be done
    }
};

pub const GameOverState = struct {
    pub fn enter(self: *GameOverState, ctx: GameStateContext) void {
        std.debug.print("[GAMEOVERSTATE] - enter\n", .{});
        _ = self;
        _ = ctx;
        // do what needs to be done
    }

    pub fn exit(self: *GameOverState) void {
        std.debug.print("[GAMEOVERSTATE] - exit\n", .{});
        _ = self;
        // do what needs to be done
    }

    pub fn update(self: *GameOverState, dt: f32) void {
        std.debug.print("[GAMEOVERSTATE] - update\n", .{});
        _ = self;
        _ = dt;
        // do what needs to be done
    }
    pub fn handleInput(self: *GameOverState, input: InputComponent) void {
        std.debug.print("[GAMEOVERSTATE] - handleInput\n", .{});
        _ = self;
        _ = input;
        // do what needs to be done
    }
};

const GameStateContext = struct {
    // hold what needs to be passed to start a stage
};
pub const GameState = union(enum) {
    MenuState: MenuState,
    PlayingState: PlayingState,
    PausedState: PausedState,
    GameOverState: GameOverState,

    pub fn enter(self: *GameState, ctx: GameStateContext) void {
        switch (self.*) {
            inline else => |*s| s.enter(ctx),
        }
    }

    pub fn exit(self: *GameState) void {
        switch (self.*) {
            inline else => |*s| s.exit(),
        }
    }

    pub fn update(self: *GameState, dt: f32) void {
        switch (self.*) {
            inline else => |*s| s.update(dt),
        }
    }
    pub fn handleInput(self: *GameState, input: InputComponent) void {
        switch (self.*) {
            inline else => |*s| s.handleInput(input),
        }
    }
};

// TODO: this needs to be moved to a real place (just for compiling reasons)
const InputComponent = struct {
    // this is just a placeholder (not where it needs to be for compiling reasons)
};
