// game/keyboard.zig
const std = @import("std");
const c = @cImport({
    @cInclude("/Users/randy/Developer/zig/zasteroids2/MacOS/Sources/CkbBridge/include/kbBridge.h");
});

// MARK: Keyboard Bridging
pub const KeyEvent = struct {
    keyCode: u8,
    isPressed: bool,
    timestamp: u64,

    // Convert from C struct
    pub fn fromC(c_event: c.kbKeyEvent) KeyEvent {
        return KeyEvent{
            .keyCode = c_event.code,
            .isPressed = c_event.isPressed != 0,
            .timestamp = c_event.timestamp,
        };
    }
};

pub const Keyboard = struct {
    // Initialize the keyboard system
    pub fn init() !void {
        std.debug.print("[KEYBOARD] - init\n", .{});
        if (c.kb_startKeyboardMonitoring() == 0) {
            std.debug.print("    !!!![KEYBOARD] - init failed\n", .{});
            return error.KeyboardMonitoringFailed;
        }
    }

    // Clean up
    pub fn deinit() void {
        c.kb_stopKeyboardMonitoring();
    }

    // Poll for the next keyboard event
    pub fn pollEvent() ?KeyEvent {
        std.debug.print("[KEYBOARD] - pollEvent\n", .{});
        var c_event: c.kbKeyEvent = undefined;
        if (c.kb_pollKeyboardEvent(&c_event) != 0) {
            return KeyEvent.fromC(c_event);
        }
        return null;
    }

    // // Check if a key is currently pressed
    // pub fn isKeyPressed(key_code: u8) bool {
    //     return c.kb_isKeyPressed(key_code) != 0;
    // }
};
