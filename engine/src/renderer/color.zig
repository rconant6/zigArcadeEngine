const std = @import("std");
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
///     const fromHex6 = Color.initFromHex("#ffffff");
///     const fromHex8 = Color.initFromHex("#01fefeff"); // Can use either 6 or 8 (alpha = 255 or alpha value)
pub const Color = struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32,

    pub fn init(r: f32, g: f32, b: f32, a: f32) Color {
        return .{ .r = r, .g = g, .b = b, .a = a };
    }

    fn hexCharToInt(comptime c: u8) u8 {
        return switch (c) {
            '0'...'9' => c - '0',
            'a'...'f' => c - 'a' + 10,
            'A'...'F' => c - 'A' + 10,
            else => @compileError("Invalid hex character"),
        };
    }

    fn parseHexPair(comptime c1: u8, comptime c2: u8) u8 {
        return hexCharToInt(c1) * 16 + hexCharToInt(c2);
    }

    pub fn initFromHex(comptime str: []const u8) Color {
        const len = str.len;
        if ((len != 7 and len != 9) or str[0] != '#')
            @compileError("Invalid hex color format: expected #RRGGBB or #RRGGBBAA\n");

        const rInt = parseHexPair(str[1], str[2]);
        const gInt = parseHexPair(str[3], str[4]);
        const bInt = parseHexPair(str[5], str[6]);
        const aInt = if (len == 9) parseHexPair(str[7], str[8]) else 255;

        return .{
            .r = @as(f32, @floatFromInt(rInt)) / 255.0,
            .g = @as(f32, @floatFromInt(gInt)) / 255.0,
            .b = @as(f32, @floatFromInt(bInt)) / 255.0,
            .a = @as(f32, @floatFromInt(aInt)) / 255.0,
        };
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

pub const Colors = struct {
    // BASIC COLORS
    pub const RED = Color.init(1, 0, 0, 1);
    pub const DARK_RED = Color.init(0.5, 0, 0, 1);
    pub const LIGHT_RED = Color.init(1, 0.7, 0.7, 1);

    pub const GREEN = Color.init(0, 1, 0, 1);
    pub const DARK_GREEN = Color.init(0, 0.5, 0, 1);
    pub const LIGHT_GREEN = Color.init(0.7, 1, 0.7, 1);

    pub const BLUE = Color.init(0, 0, 1, 1);
    pub const DARK_BLUE = Color.init(0, 0, 0.5, 1);
    pub const LIGHT_BLUE = Color.init(0.7, 0.7, 1, 1);

    pub const CYAN = Color.init(0, 1, 1, 1);
    pub const MAGENTA = Color.init(1, 0, 1, 1);
    pub const YELLOW = Color.init(1, 1, 0, 1);
    // EXTENDED COLORS
    pub const ORANGE = Color.init(1, 0.5, 0, 1);
    pub const DARK_ORANGE = Color.init(1, 0.3, 0, 1);
    pub const LIGHT_ORANGE = Color.init(1, 0.8, 0.6, 1);

    pub const PURPLE = Color.init(0.5, 0, 0.5, 1);
    pub const DARK_PURPLE = Color.init(0.3, 0, 0.3, 1);
    pub const LIGHT_PURPLE = Color.init(0.8, 0.6, 0.8, 1);

    pub const PINK = Color.init(1, 0.75, 0.8, 1);
    pub const BROWN = Color.init(0.6, 0.4, 0.2, 1);
    pub const LIME = Color.init(0.75, 1, 0, 1);

    // NON-COLORS
    pub const WHITE = Color.init(1, 1, 1, 1);
    pub const BLACK = Color.init(0, 0, 0, 1);
    pub const CLEAR = Color.init(0, 0, 0, 0);

    pub const LIGHT_GRAY = Color.init(0.75, 0.75, 0.75, 1);
    pub const GRAY = Color.init(0.5, 0.5, 0.5, 1);
    pub const DARK_GRAY = Color.init(0.25, 0.25, 0.25, 1);

    // NEONS
    pub const NEON_RED = Color.init(1, 0.1, 0.1, 1);
    pub const NEON_GREEN = Color.init(0.1, 1, 0.1, 1);
    pub const NEON_BLUE = Color.init(0.1, 0.1, 1, 1);
    pub const NEON_CYAN = Color.init(0.1, 1, 1, 1);
    pub const NEON_MAGENTA = Color.init(1, 0.1, 1, 1);
    pub const NEON_YELLOW = Color.init(1, 1, 0.1, 1);
    pub const NEON_ORANGE = Color.init(1, 0.4, 0.1, 1);
    pub const NEON_PURPLE = Color.init(0.8, 0.1, 1, 1);
    pub const NEON_PINK = Color.init(1, 0.1, 0.6, 1);

    // PASTELS
    pub const PASTEL_RED = Color.init(1, 0.8, 0.8, 1);
    pub const PASTEL_GREEN = Color.init(0.8, 1, 0.8, 1);
    pub const PASTEL_BLUE = Color.init(0.8, 0.8, 1, 1);
    pub const PASTEL_CYAN = Color.init(0.8, 1, 1, 1);
    pub const PASTEL_MAGENTA = Color.init(1, 0.8, 1, 1);
    pub const PASTEL_YELLOW = Color.init(1, 1, 0.8, 1);
    pub const PASTEL_ORANGE = Color.init(1, 0.9, 0.8, 1);
    pub const PASTEL_PURPLE = Color.init(0.9, 0.8, 1, 1);
    pub const PASTEL_PINK = Color.init(1, 0.8, 0.9, 1);
};
