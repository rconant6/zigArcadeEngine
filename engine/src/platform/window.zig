const std = @import("std");

const plat = @import("platform.zig");
const c = plat.c;

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

    pub fn updateWindowPixels(self: *Window, colors: []const u8, width: usize, height: usize) void {
        c.wb_updateWindowPixels(
            self.id,
            @ptrCast(colors.ptr),
            @intCast(width),
            @intCast(height),
        );
    }
};
