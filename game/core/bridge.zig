const std = @import("std");
pub const c = @cImport({
    @cInclude("/Users/randy/Developer/zig/zasteroids2/MacOS/Sources/CBridge/kb/include/kbBridge.h");
    @cInclude("/Users/randy/Developer/zig/zasteroids2/MacOS/Sources/CBridge/w/include/wBridge.h");
});

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
        c.wb_destroyWindow(self.id);
        self.id = 0;
    }

    pub fn shouldClose(self: Window) bool {
        return c.wb_shouldWindowClose(self.id) != 0;
    }
};

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
