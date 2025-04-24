// game/keyboard.zig
const std = @import("std");
const c = @cImport({
    @cInclude("/Users/randy/Developer/zig/zasteroids2/MacOS/Sources/CkbBridge/include/kbBridge.h");
});

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
        if (c.kb_startKeyboardMonitoring() == 0) {
            return error.KeyboardMonitoringFailed;
        }
    }

    // Clean up
    pub fn deinit() void {
        c.kb_stopKeyboardMonitoring();
    }

    // Poll for the next keyboard event
    pub fn pollEvent() ?KeyEvent {
        var c_event: c.kbKeyEvent = undefined;
        if (c.kb_pollKeyboardEvent(&c_event) != 0) {
            return KeyEvent.fromC(c_event);
        }
        return null;
    }

    // Check if a key is currently pressed
    pub fn isKeyPressed(key_code: u8) bool {
        return c.kb_isKeyPressed(key_code) != 0;
    }
};
