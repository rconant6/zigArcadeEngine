const std = @import("std");

pub const V2 = struct {
    x: f32,
    y: f32,

    pub fn add(self: V2, other: V2) V2 {
        return V2{ .x = self.x + other.x, .y = self.y + other.y };
    }

    pub fn sub(self: V2, other: V2) V2 {
        return V2{ .x = self.x - other.x, .y = self.y - other.y };
    }

    pub fn mul(self: V2, scalar: f32) V2 {
        return V2{ .x = self.x * scalar, .y = self.y * scalar };
    }

    pub fn div(self: V2, scalar: f32) V2 {
        std.debug.assert(scalar != 0);
        return V2{ .x = self.x / scalar, .y = self.y / scalar };
    }

    pub fn eql(self: V2, other: V2) bool {
        const epsilon = 0.0001;
        return @abs(self.x - other.x) < epsilon and @abs(self.y - other.y) < epsilon;
    }

    pub fn magnitude(self: V2) f32 {
        return std.math.sqrt(self.x * self.x + self.y * self.y);
    }

    pub fn normalize(self: V2) V2 {
        return self.div(self.magnitude());
    }

    pub fn distance(self: V2, other: V2) f32 {
        return (self.sub(other)).magnitude();
    }

    pub const ZERO = V2{ .x = 0, .y = 0 };
};
