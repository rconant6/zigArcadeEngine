const std = @import("std");

const Keyboard = @import("../core/bridge.zig").Keyboard;
const KeyEvent = @import("../core/bridge.zig").KeyEvent;
const InputSystem = @import("../systems/inputSystem.zig").InputSystem;
const InputEvent = @import("../systems/inputSystem.zig").InputEvent;

const KeyCode = enum(u8) {
    P = 0x19, // Play/Pause
    A = 0x1E, // Rotate Counter-clockwise
    S = 0x1F, // Reverse (maybe mini nose thrusters)
    D = 0x20, // Rotate Clockwise
    W = 0x11, // Thrust Forward
    Enter = 0x1C, // Start Game
    Space = 0x39, // Shoot
    Esc = 0xff, // Quit TODO: need the real code
};

pub const GameAction = enum {
    Thrust,
    RotateLeft,
    RotateRight,
    Fire,
    Start,
    PausePlay,
    Quit,
};

pub const ActionKeyMap = struct {
    // Static mapping defined at compile time
    const mappings = [_]struct { action: GameAction, key: u8 }{
        .{ .key = @intFromEnum(KeyCode.W), .action = GameAction.Thrust },
        .{ .key = @intFromEnum(KeyCode.A), .action = GameAction.RotateLeft },
        .{ .key = @intFromEnum(KeyCode.D), .action = GameAction.RotateRight },
        .{ .key = @intFromEnum(KeyCode.Space), .action = GameAction.Fire },
        .{ .key = @intFromEnum(KeyCode.Enter), .action = GameAction.Start },
        .{ .key = @intFromEnum(KeyCode.P), .action = GameAction.PausePlay },
        .{ .key = @intFromEnum(KeyCode.Esc), .action = GameAction.Quit },
    };

    pub fn getActionForKey(key: u8) ?GameAction {
        inline for (mappings) |mapping| {
            if (mapping.key == key) {
                return mapping.action;
            }
        }
        return null;
    }
};

pub const InputManager = struct {
    allocator: *std.mem.Allocator,
    inputSystem: *InputSystem,

    pub fn init(allocator: *std.mem.Allocator, system: *InputSystem) !InputManager {
        return InputManager{
            .allocator = allocator,
            .inputSystem = system,
        };
    }

    pub fn deinit(self: *InputManager) void {
        _ = self;
        Keyboard.deinit();
    }

    pub fn update(self: *InputManager) !void {
        std.debug.print("[INPUTMANAGER] - update\n", .{});
        var iteration_count: u32 = 0;
        const MAX_ITERATIONS: u32 = 1000; // Adjust as needed
        // Poll keyboard for new events
        while (Keyboard.pollEvent()) |keyEvent| {
            std.debug.print(
                "   ----[INPUTMANAGER] - Got keyboard event: code={}, pressed={}\n",
                .{ keyEvent.keyCode, keyEvent.isPressed },
            );
            // Create an InputEvent that your InputSystem expects
            const inputEvent = InputEvent{
                .time = keyEvent.timestamp,
                .data = .{
                    .key = .{
                        .code = keyEvent.keyCode,
                        .isPressed = keyEvent.isPressed,
                    },
                },
            };

            // Add the event to your existing InputSystem queue
            try self.inputSystem.addEvent(inputEvent);
            iteration_count += 1;
            if (iteration_count >= MAX_ITERATIONS) {
                std.debug.print("WARNING: Breaking out of potentially infinite keyboard event loop\n", .{});
                break;
            }
        }
    }
};
