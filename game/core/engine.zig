const std = @import("std");

pub const Engine = struct {
    arena: std.heap.ArenaAllocator,
    isRunning: bool,
    targetFPS: u32,

    pub fn init(allocator: std.mem.Allocator) Engine {
        std.debug.print("[ENGINE] intializing...\n", .{});
        return Engine{
            .arena = std.heap.ArenaAllocator.init(allocator),
            .isRunning = true,
            .targetFPS = 60, // FPS
        };
    }
    pub fn deinit(self: *Engine) void {
        std.debug.print("[ENGINE] de-intializing...\n", .{});
        self.arena.deinit();
    }

    pub fn run(self: *Engine) !void {
        std.debug.print("[ENGINE] running\n", .{});
        const frameDuration = std.time.ms_per_s / self.targetFPS; // 1_000_000 PS / 60 FPS
        var frameStart: i64 = 0;
        var frameEnd: i64 = 0;
        var sleepDuration: i64 = 0;
        var elapsed: i64 = 0;
        var frameCount: i64 = 0;
        while (self.isRunning) : (frameCount += 1) {
            std.debug.print("[ENGINE] frameCount: {d}\n", .{frameCount});
            frameStart = std.time.microTimestamp();
            try self.update();
            try self.render();
            frameEnd = std.time.microTimestamp();
            elapsed = frameEnd - frameStart;
            sleepDuration = frameDuration - elapsed;

            if (sleepDuration > 0) {
                std.debug.print("sleepDuration {d}\n", .{sleepDuration});
                std.Thread.sleep(@intCast(sleepDuration * std.time.ms_per_s));
            }
        }
    }

    fn update(self: *Engine) !void {
        _ = self;
        std.debug.print("[ENGINE] - update\n", .{});
        // do some update stuff (right now just wait for a q)
    }

    fn render(self: *Engine) !void {
        _ = self;
        std.debug.print("[ENGINE] - render\n", .{});
        // do the rendering stuff
    }
};
