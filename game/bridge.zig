const std = @import("std");
pub const c = @cImport({
    @cInclude("/Users/randy/Developer/zig/zasteroids2/MacOS/Sources/CBridge/kb/include/kbBridge.h");
    @cInclude("/Users/randy/Developer/zig/zasteroids2/MacOS/Sources/CBridge/w/include/wBridge.h");
});

pub const Color = @import("renderer.zig").Color;

// MARK: Window Bridging
pub const WindowConfig = struct {
    width: f32,
    height: f32,
    title: [:0]const u8,
};

pub const Window = struct {
    id: u32,

    pub fn create(config: WindowConfig) !Window {
        std.debug.print("[WINDOW] - create\n", .{});
        const c_config = c.wbWindowConfig{
            .width = config.width,
            .height = config.height,
            .title = config.title.ptr,
        };

        const window_id = c.wb_createWindow(c_config);
        if (window_id == 0) {
            return error.WindowCreationFailed;
        }

        return Window{
            .id = window_id,
        };
    }

    pub fn processEvents(self: *Window) void {
        _ = self;
        c.wb_processEvents();
    }

    pub fn destroy(self: *Window) void {
        std.debug.print("[WINDOW] - destroy\n", .{});
        c.wb_destroyWindow(self.id);
        self.id = 0;
    }

    pub fn shouldClose(self: Window) bool {
        return c.wb_shouldWindowClose(self.id) != 0;
    }

    // link data from the renderer
    pub fn updateWindowPixels(self: *Window, colors: []const Color, width: usize, height: usize) void {
        c.wb_updateWindowPixels(
            self.id,
            @ptrCast(colors.ptr),
            @intCast(width),
            @intCast(height),
        );
    }
};

// MARK: Keyboard Bridging
pub const GameKeyCode = enum(u8) {
    A = 0,
    W = 1,
    S = 2,
    D = 3,

    Left = 4,
    Right = 5,
    Up = 6,
    Down = 7,

    P = 8,
    Enter = 9,
    Space = 10,
    Esc = 11,
    GameOver = 12, // placeholder to manually send when met?

    Unused = 255,
};

fn mapToGameKeyCode(osKeyCode: u8) GameKeyCode {
    if (comptime std.Target.Os.Tag.macos == .macos) {
        // Default mapping for MacOS
        return switch (osKeyCode) {
            0x00 => .A,
            0x0D => .W,
            0x01 => .S,
            0x02 => .D,
            0x7B => .Left,
            0x7C => .Right,
            0x7E => .Up,
            0x7D => .Down,
            0x23 => .P,
            0x24 => .Enter,
            0x31 => .Space,
            0x35 => .Esc,
            else => .Unused,
        };
    } else {
        // Default mapping for other platforms (PC standard)
        std.debug.print("here for some reason\n", .{});
        return switch (osKeyCode) {
            // WASD keys
            0x04 => .A,
            0x1A => .W,
            0x16 => .S,
            0x07 => .D,

            // Arrow keys
            0x4B => .Left, // Left arrow on PC
            0x4D => .Right, // Right arrow on PC
            0x48 => .Up, // Up arrow on PC
            0x50 => .Down, // Down arrow on PC

            // Action keys
            0x13 => .P,
            0x28 => .Enter,
            0x2C => .Space,
            0x29 => .Esc,

            else => .Unused,
        };
    }
}

pub const KeyEvent = struct {
    keyCode: GameKeyCode,
    isPressed: bool,
    timestamp: u64,

    // Convert from C struct
    pub fn fromC(c_event: c.kbKeyEvent) KeyEvent {
        const keyCode = mapToGameKeyCode(c_event.code);
        return KeyEvent{
            .keyCode = keyCode,
            .isPressed = c_event.isPressed != 0,
            .timestamp = c_event.timestamp,
        };
    }
};

pub const Keyboard = struct {
    pub fn init() !Keyboard {
        std.debug.print("[KEYBOARD] - init\n", .{});
        if (c.kb_startKeyboardMonitoring() == 0) {
            return error.KeyboardMonitoringFailed;
        }
        return Keyboard{};
    }

    pub fn deinit(self: *Keyboard) void {
        std.debug.print("[KEYBOARD] - deinit\n", .{});
        _ = self;
        c.kb_stopKeyboardMonitoring();
    }

    pub fn pollEvent(self: *Keyboard) ?KeyEvent {
        _ = self;
        var c_event: c.kbKeyEvent = undefined;
        if (c.kb_pollKeyboardEvent(&c_event) != 0) {
            return KeyEvent.fromC(c_event);
        }
        return null;
    }
};

// MARK: GameState bridging
pub const GameStateContext = struct {
    // hold what needs to be passed to start a stage
    // this probably collects alot of optional stuff
    // that each GameState will copy/set in its enter function
    // exit can take a pointer to update it
};

pub const StateTransitions = enum {
    MenuToPlay,
    PauseToPlay,
    PauseToMenu,
    PlayToMenu,
    PlayToPause,
    PlayToGameOver,
    GameOverToMenu,
};
