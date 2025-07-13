const std = @import("std");

pub const V2I = struct {
    x: i32,
    y: i32,

    pub fn add(self: V2I, other: V2I) V2I {
        return V2I{ .x = self.x + other.x, .y = self.y + other.y };
    }

    pub fn sub(self: V2I, other: V2I) V2I {
        return V2I{ .x = self.x - other.x, .y = self.y - other.y };
    }

    pub fn mul(self: V2I, scalar: i32) V2I {
        return V2I{ .x = self.x * scalar, .y = self.y * scalar };
    }

    pub fn div(self: V2I, scalar: i32) V2I {
        std.debug.assert(scalar != 0);
        return V2I{ .x = @divFloor(self.x, scalar), .y = @divFloor(self.y, scalar) };
    }

    pub fn magnitude(self: V2I) f32 {
        const fx: f32 = @floatFromInt(self.x);
        const fy: f32 = @floatFromInt(self.y);
        return std.math.sqrt(fx * fx + fy * fy);
    }

    pub fn normalize(self: V2I) V2I {
        const mag = self.magnitude();
        return V2I{
            .x = @intFromFloat(@as(f32, @floatFromInt(self.x)) / mag),
            .y = @intFromFloat(@as(f32, @floatFromInt(self.y)) / mag),
        };
    }

    pub fn distance(self: V2I, other: V2I) f32 {
        return (self.sub(other)).magnitude();
    }

    pub fn zero() V2I {
        return .{ .x = 0, .y = 0 };
    }
};
