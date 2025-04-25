const std = @import("std");

const Engine = @import("core/engine.zig").Engine;

pub fn main() void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocator = gpa.allocator();

    std.debug.print("[MAIN] starting up\n", .{});

    var engine: Engine = Engine.init(&allocator) catch |err| {
        std.debug.print("[MAIN] unable to initialize engine: {any}\n", .{err});
        unreachable;
    };
    defer engine.deinit();
    engine.run() catch |err| {
        std.debug.print("[MAIN] engine catostrophic error: {any}\n", .{err});
    };

    std.debug.print("[MAIN] tearing down\n", .{});
}
