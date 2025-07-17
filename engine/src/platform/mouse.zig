pub const std = @import("std");
const builtin = @import("builtin");

pub const plat = @import("platform.zig");
const c = plat.c;

pub const Mouse = struct {
    pub fn init() !Mouse {
        std.debug.print("[MOUSE] - init\n", .{});
        // TODO: Initialize mouse monitoring
        return Mouse{};
    }

    pub fn deinit(self: *Mouse) void {
        std.debug.print("[MOUSE] - deinit\n", .{});
        _ = self;
        // TODO: Cleanup mouse monitoring
    }

    pub fn pollEvent(self: *Mouse) ?MouseEvent {
        _ = self;
        // TODO: Poll for mouse events from C bridge
        return null;
    }
};

pub const MouseEvent = struct {
    button: MouseButton,
    isPressed: bool,
    x: f32,
    y: f32,
    timestamp: u64,

    // Convert from C struct (placeholder)
    pub fn fromC(c_event: anytype) ?MouseEvent {
        _ = c_event;
        // TODO: Convert from C mouse event
        return MouseEvent{
            .button = .Left,
            .isPressed = false,
            .x = 0.0,
            .y = 0.0,
            .timestamp = 0,
        };
    }
};

pub const MouseButton = enum(u8) {
    Left = 0,
    Right = 1,
    Middle = 2,
    Button4 = 3,
    Button5 = 4,
    // TODO: Add more buttons as needed
    Unused = 255,
};
