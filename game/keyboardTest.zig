// game/keyboard_test.zig
const std = @import("std");
const kb = @import("keyboard");

pub fn main() !void {
    // Initialize
    try kb.Keyboard.init();
    defer kb.Keyboard.deinit();

    const stdout = std.io.getStdOut().writer();

    try stdout.print("Keyboard monitor initialized successfully!\n", .{});
    try stdout.print("Press keys to see events (Ctrl+C to exit)...\n\n", .{});

    // Simple event loop
    while (true) {
        // Check for events
        while (kb.Keyboard.pollEvent()) |event| {
            try stdout.print("Key: {d} - {s} (Time: {d})\n", .{
                event.keyCode,
                if (event.isPressed) "PRESSED" else "RELEASED",
                event.timestamp,
            });
        }

        // Small delay to avoid hogging CPU
        std.time.sleep(10 * std.time.ns_per_ms);
    }
}
