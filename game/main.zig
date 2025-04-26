const std = @import("std");
const bridge = @import("core/bridge.zig");

const Engine = @import("core/engine.zig").Engine;

// pub fn main() !void {
//     std.debug.print("[MAIN] Starting app\n", .{});
//
//     const app = bridge.c.wb_initApplication();
//     std.debug.print("[MAIN] App initialization returned: {d}\n", .{app});
//
//     if (app == 0) {
//         std.debug.print("[MAIN] Failed to initialize application\n", .{});
//         return error.ApplicationInitFailed;
//     }
//
//     // Make application visible
//     const visible = bridge.c.wb_makeApplicationVisible();
//     std.debug.print("[MAIN] App visible: {d}\n", .{visible});
//
//     // Create window with bright blue color for visibility
//     var window = try bridge.Window.create(.{
//         .width = 800,
//         .height = 600,
//         .title = "My Window",
//     });
//     defer window.destroy();
//
//     // Initialize keyboard
//     try bridge.Keyboard.init();
//     defer bridge.Keyboard.deinit();
//
//     // Main loop with more frequent processing
//     var frame_count: u32 = 0;
//     while (!window.shouldClose()) {
//         frame_count += 1;
//
//         // Process macOS events
//         window.processEvents();
//
//         // Poll for keyboard events
//         if (bridge.Keyboard.pollEvent()) |event| {
//             std.debug.print("[MAIN] Key event: code={d}, pressed={}\n", .{ event.keyCode, event.isPressed });
//         }
//         // std.time.sleep(16 * std.time.ns_per_ms);
//     }
//
//     std.debug.print("[MAIN] Exiting main loop\n", .{});
// }
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocator = gpa.allocator();

    std.debug.print("[MAIN] starting up\n", .{});
    var engine: Engine = Engine.init(&allocator) catch |err| {
        std.debug.print("[MAIN] unable to initialize engine: {any}\n", .{err});
        std.process.exit(65);
    };
    defer engine.deinit();
    engine.run() catch |err| {
        std.debug.print("[MAIN] engine catostrophic error: {any}\n", .{err});
    };

    std.debug.print("[MAIN] tearing down\n", .{});
}
