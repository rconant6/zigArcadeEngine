const std = @import("std");
const bridge = @import("core/bridge.zig");

const Engine = @import("core/engine.zig").Engine;
const GameConfig = @import("core/engine.zig").GameConfig;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocator = gpa.allocator();

    std.debug.print("[MAIN] starting up\n", .{});
    const config = GameConfig{
        .windowTitle = "ZASTEROIDS",
        .windowWidth = 1900,
        .windowHeight = 1200,
    };

    var engine: Engine = Engine.init(&allocator, config) catch |err| {
        std.debug.print("[MAIN] unable to initialize engine: {any}\n", .{err});
        std.process.exit(65);
    };
    defer engine.deinit();
    engine.run() catch |err| {
        std.debug.print("[MAIN] engine catostrophic error: {any}\n", .{err});
    };

    std.debug.print("[MAIN] tearing down\n", .{});
}
