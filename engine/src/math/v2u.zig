const std = @import("std");

pub const V2U = struct {
    x: u32,
    y: u32,

    pub fn add(self: V2U, other: V2U) V2U {
        return V2U{ .x = self.x + other.x, .y = self.y + other.y };
    }

    pub fn sub(self: V2U, other: V2U) V2U {
        return V2U{ .x = self.x - other.x, .y = self.y - other.y };
    }

    pub fn mul(self: V2U, scalar: u32) V2U {
        return V2U{ .x = self.x * scalar, .y = self.y * scalar };
    }

    pub fn div(self: V2U, scalar: u32) V2U {
        std.debug.assert(scalar != 0);
        return V2U{ .x = self.x / scalar, .y = self.y / scalar };
    }

    pub fn magnitude(self: V2U) f32 {
        const fx: f32 = @floatFromInt(self.x);
        const fy: f32 = @floatFromInt(self.y);
        return std.math.sqrt(fx * fx + fy * fy);
    }

    pub fn normalize(self: V2U) V2U {
        const mag = self.magnitude();
        return V2U{
            .x = @intFromFloat(@as(f32, @floatFromInt(self.x)) / mag),
            .y = @intFromFloat(@as(f32, @floatFromInt(self.y)) / mag),
        };
    }

    pub fn distance(self: V2U, other: V2U) f32 { // Return f32
        return (self.sub(other)).magnitude();
    }

    pub fn zero() V2U {
        return .{ .x = 0, .y = 0 };
    }
};
