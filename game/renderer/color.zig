/// Represents a color with red, green, blue, and alpha channels.
///
/// Color components are stored as normalized floating-point values (0.0 to 1.0).
/// The alpha channel controls transparency, where 0.0 is fully transparent
/// and 1.0 is fully opaque.
///
/// Example:
///     const red = Color.init(1, 0, 0, 1);         // Opaque red
///     const transparentBlue = Color.init(0, 0, 1, 0.5); // Semi-transparent blue
///     const fromBytes = Color.initFromInt(255, 128, 0, 255); // Orange from byte values
pub const Color = struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32,

    pub fn init(r: f32, g: f32, b: f32, a: f32) Color {
        return .{ .r = r, .g = g, .b = b, .a = a };
    }

    pub fn initFromInt(r: u8, g: u8, b: u8, a: u8) Color {
        return .{
            .r = @as(f32, @floatFromInt(r)) / 255.0,
            .g = @as(f32, @floatFromInt(g)) / 255.0,
            .b = @as(f32, @floatFromInt(b)) / 255.0,
            .a = @as(f32, @floatFromInt(a)) / 255.0,
        };
    }
};
