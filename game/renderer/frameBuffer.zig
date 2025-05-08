const std = @import("std");

const Color = @import("color.zig").Color;

pub const FrameBuffer = struct {
    width: i32,
    height: i32,
    frontBuffer: []Color,
    backBuffer: []Color,
    bufferMemory: []Color,
    arena: std.heap.ArenaAllocator,

    pub fn init(allocator: *std.mem.Allocator, width: i32, height: i32) !FrameBuffer {
        // allocate memory for both buffers
        // initialize w/ default values
        const bufSize: usize = @intCast(width * height);
        var arena = std.heap.ArenaAllocator.init(allocator.*);

        const bufferMemory = try arena.allocator().alloc(Color, bufSize * 2);
        const front = bufferMemory[0..bufSize];
        const back = bufferMemory[bufSize..];

        const defaultColor = Color.init(0, 0, 0, 0);
        for (bufferMemory) |*pixel| {
            pixel.* = defaultColor;
        }

        return .{
            .width = width,
            .height = height,
            .arena = arena,
            .frontBuffer = front,
            .backBuffer = back,
            .bufferMemory = bufferMemory,
        };
    }

    pub fn deinit(self: *FrameBuffer) void {
        self.arena.deinit();
    }

    pub fn clear(self: *FrameBuffer, color: Color) void {
        for (self.backBuffer) |*pixel| {
            pixel.* = color;
        }
    }

    pub fn setPixel(self: *FrameBuffer, x: i32, y: i32, color: Color) void {
        if (x < 0 or y < 0 or x >= self.width or y >= self.height) {
            return;
        }

        const index: usize = @intCast(y * self.width + x);
        self.backBuffer[index] = color;
    }

    pub fn getPixel(self: *FrameBuffer, x: i32, y: i32) ?Color {
        if (x < 0 or y < 0 or x >= self.width or y >= self.height) {
            return null;
        }

        const index: usize = @intCast(y * self.width + x);
        return self.backBuffer[index];
    }

    pub fn swapBuffers(self: *FrameBuffer) void {
        const temp = self.frontBuffer;
        self.frontBuffer = self.backBuffer;
        self.backBuffer = temp;
    }
};
